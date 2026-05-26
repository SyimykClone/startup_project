import math
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from app.deps.auth import require_auth
from app.models.route import RouteHistoryItem, RouteRequest, RouteResponse
from app.services.gamification_repo import register_route_built
from app.services.route_history_repo import list_route_history, save_route_history
from app.services.twogis_service import (
    TwoGisError,
    categories_list,
    categories_search,
    geocode,
    place_by_id,
    places_search,
    public_transport,
    resolve_tap,
    routing,
    suggest,
)

router = APIRouter(
    prefix="/api/2gis",
    tags=["2gis"],
    dependencies=[Depends(require_auth)],
)


class TourRoutePoint(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)


class TourRouteRequest(BaseModel):
    points: list[TourRoutePoint] = Field(min_length=2, max_length=12)
    profile: str = Field(default="driving", pattern="^(walking|driving)$")


def _handle_twogis_error(e: Exception) -> HTTPException:
    if isinstance(e, TwoGisError):
        return HTTPException(status_code=400, detail=str(e))
    return HTTPException(status_code=500, detail=f"Unexpected error: {e}")


def _distance_m(from_lat: float, from_lng: float, to_lat: float, to_lng: float) -> float:
    radius = 6371000
    lat1 = math.radians(from_lat)
    lat2 = math.radians(to_lat)
    d_lat = math.radians(to_lat - from_lat)
    d_lng = math.radians(to_lng - from_lng)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(lat1) * math.cos(lat2) * math.sin(d_lng / 2) ** 2
    )
    return 2 * radius * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _number_from(obj: Any, keys: tuple[str, ...]) -> float | None:
    if not isinstance(obj, dict):
        return None
    for key in keys:
        value = obj.get(key)
        if isinstance(value, (int, float)):
            return float(value)
        if isinstance(value, str):
            try:
                return float(value)
            except ValueError:
                continue
    return None


def _point_to_coordinate(point: Any) -> list[float] | None:
    if isinstance(point, dict):
        lat = point.get("lat") or point.get("latitude") or point.get("y")
        lng = (
            point.get("lon")
            or point.get("lng")
            or point.get("longitude")
            or point.get("x")
        )
        if isinstance(lat, (int, float)) and isinstance(lng, (int, float)):
            return [float(lng), float(lat)]
    if isinstance(point, (list, tuple)) and len(point) >= 2:
        first, second = point[0], point[1]
        if isinstance(first, (int, float)) and isinstance(second, (int, float)):
            return [float(first), float(second)]
    return None


def _linestring_to_coordinates(value: Any) -> list[list[float]]:
    if not isinstance(value, str):
        return []
    text = value.strip()
    if not text.upper().startswith("LINESTRING"):
        return []
    start = text.find("(")
    end = text.rfind(")")
    if start < 0 or end <= start:
        return []

    coordinates: list[list[float]] = []
    for raw_point in text[start + 1 : end].split(","):
        parts = raw_point.strip().split()
        if len(parts) < 2:
            continue
        try:
            lng = float(parts[0])
            lat = float(parts[1])
        except ValueError:
            continue
        coordinates.append([lng, lat])
    return coordinates


def _selection_coordinates_deep(value: Any) -> list[list[float]]:
    if isinstance(value, str):
        return _linestring_to_coordinates(value)

    if isinstance(value, list):
        coordinates: list[list[float]] = []
        for item in value:
            item_coordinates = _selection_coordinates_deep(item)
            if item_coordinates:
                if coordinates and coordinates[-1] == item_coordinates[0]:
                    coordinates.extend(item_coordinates[1:])
                else:
                    coordinates.extend(item_coordinates)
        return coordinates

    if isinstance(value, dict):
        coordinates: list[list[float]] = []
        preferred_keys = (
            "begin_pedestrian_path",
            "maneuvers",
            "outcoming_path",
            "end_pedestrian_path",
            "segments",
            "geometry",
            "selection",
            "walking_path",
            "transport_path",
            "path",
        )
        for key in preferred_keys:
            if key not in value:
                continue
            item_coordinates = _selection_coordinates_deep(value[key])
            if item_coordinates:
                if coordinates and coordinates[-1] == item_coordinates[0]:
                    coordinates.extend(item_coordinates[1:])
                else:
                    coordinates.extend(item_coordinates)
        if coordinates:
            return coordinates
        for key, item in value.items():
            if key not in preferred_keys:
                item_coordinates = _selection_coordinates_deep(item)
                if item_coordinates:
                    return item_coordinates
    return []


def _extract_coordinates(route: Any) -> list[list[float]]:
    if not isinstance(route, dict):
        return []

    geometry = route.get("geometry")
    if isinstance(geometry, dict):
        coordinates = geometry.get("coordinates")
        if isinstance(coordinates, list):
            parsed = [_point_to_coordinate(item) for item in coordinates]
            return [item for item in parsed if item is not None]
    if isinstance(geometry, list):
        parsed = [_point_to_coordinate(item) for item in geometry]
        return [item for item in parsed if item is not None]

    for key in ("points", "path", "polyline"):
        points = route.get(key)
        if isinstance(points, list):
            parsed = [_point_to_coordinate(item) for item in points]
            coordinates = [item for item in parsed if item is not None]
            if coordinates:
                return coordinates
    return []


def _nested_dicts(value: Any) -> list[dict[str, Any]]:
    if isinstance(value, dict):
        nested = [value]
        for child in value.values():
            nested.extend(_nested_dicts(child))
        return nested
    if isinstance(value, list):
        nested = []
        for child in value:
            nested.extend(_nested_dicts(child))
        return nested
    return []


def _first_route(raw: Any) -> dict[str, Any]:
    if isinstance(raw, list) and raw and isinstance(raw[0], dict):
        return raw[0]
    if not isinstance(raw, dict):
        return {}
    result = raw.get("result")
    containers = [raw]
    if isinstance(result, dict):
        containers.insert(0, result)
    elif isinstance(result, list) and result and isinstance(result[0], dict):
        return result[0]

    for container in containers:
        for key in ("routes", "items"):
            routes = container.get(key)
            if isinstance(routes, list) and routes and isinstance(routes[0], dict):
                return routes[0]
    return {}


def _first_number_deep(raw: Any, keys: tuple[str, ...]) -> float | None:
    for item in _nested_dicts(raw):
        value = _number_from(item, keys)
        if value is not None:
            return value
    return None


def _is_coordinate_pair(value: Any) -> bool:
    if not isinstance(value, (list, tuple)) or len(value) < 2:
        return False
    first, second = value[0], value[1]
    if not isinstance(first, (int, float)) or not isinstance(second, (int, float)):
        return False
    return -180 <= first <= 180 and -90 <= second <= 90


def _coordinate_lists_deep(value: Any) -> list[list[list[float]]]:
    if isinstance(value, list):
        parsed_points = [_point_to_coordinate(item) for item in value]
        coordinates = [item for item in parsed_points if item is not None]
        if len(coordinates) >= 2:
            return [coordinates]

        if len(value) >= 2 and all(_is_coordinate_pair(item) for item in value):
            parsed = [_point_to_coordinate(item) for item in value]
            coordinates = [item for item in parsed if item is not None]
            if len(coordinates) >= 2:
                return [coordinates]

        results: list[list[list[float]]] = []
        for item in value:
            results.extend(_coordinate_lists_deep(item))
        return results

    if isinstance(value, dict):
        preferred_keys = (
            "coordinates",
            "points",
            "path",
            "polyline",
            "geometry",
            "selection",
            "outcoming_path",
            "walking_path",
        )
        results = []
        for key in preferred_keys:
            if key in value:
                results.extend(_coordinate_lists_deep(value[key]))
        for key, item in value.items():
            if key not in preferred_keys:
                results.extend(_coordinate_lists_deep(item))
        return results

    return []


def _coordinates_deep(raw: Any) -> list[list[float]]:
    selection_coordinates = _selection_coordinates_deep(raw)
    if len(selection_coordinates) >= 2:
        return selection_coordinates

    deep_candidates = _coordinate_lists_deep(raw)
    if deep_candidates:
        return max(deep_candidates, key=len)

    for item in _nested_dicts(raw):
        coordinates = _extract_coordinates(item)
        if len(coordinates) >= 2:
            return coordinates

        for key in ("points", "coordinates", "geometry", "path", "polyline"):
            value = item.get(key)
            if isinstance(value, list):
                parsed = [_point_to_coordinate(point) for point in value]
                coordinates = [point for point in parsed if point is not None]
                if len(coordinates) >= 2:
                    return coordinates
    return []


def _endpoint_score(
    coordinates: list[list[float]],
    req: RouteRequest,
) -> float:
    if len(coordinates) < 2:
        return float("inf")
    start_lng, start_lat = coordinates[0]
    end_lng, end_lat = coordinates[-1]
    forward = _distance_m(req.from_lat, req.from_lng, start_lat, start_lng)
    forward += _distance_m(req.to_lat, req.to_lng, end_lat, end_lng)
    backward = _distance_m(req.from_lat, req.from_lng, end_lat, end_lng)
    backward += _distance_m(req.to_lat, req.to_lng, start_lat, start_lng)
    return min(forward, backward)


def _normalize_route_coordinates(
    coordinates: list[list[float]],
    req: RouteRequest,
) -> list[list[float]]:
    if len(coordinates) < 2:
        return []

    original = coordinates
    swapped = [[point[1], point[0]] for point in coordinates if len(point) >= 2]
    candidates = [original, swapped]
    best = min(candidates, key=lambda item: _endpoint_score(item, req))

    fallback_distance = _distance_m(req.from_lat, req.from_lng, req.to_lat, req.to_lng)
    max_allowed_endpoint_error = max(250.0, fallback_distance * 0.45)
    if _endpoint_score(best, req) > max_allowed_endpoint_error:
        return []
    return best


def _route_response_from_2gis(
    raw: Any,
    req: RouteRequest,
) -> RouteResponse:
    route = _first_route(raw)
    summary = route.get("summary") if isinstance(route.get("summary"), dict) else {}

    distance = (
        _number_from(route, ("distance", "distance_m", "total_distance", "length"))
        or _number_from(summary, ("distance", "distance_m", "total_distance", "length"))
        or _first_number_deep(raw, ("distance", "distance_m", "total_distance", "length"))
    )
    duration = (
        _number_from(route, ("duration", "duration_s", "total_duration", "time"))
        or _number_from(summary, ("duration", "duration_s", "total_duration", "time"))
        or _first_number_deep(raw, ("duration", "duration_s", "total_duration", "time"))
    )

    coordinates = _selection_coordinates_deep(route)
    if len(coordinates) < 2:
        coordinates = _selection_coordinates_deep(raw)
    if len(coordinates) < 2:
        coordinates = _extract_coordinates(route)
    if len(coordinates) < 2:
        coordinates = _coordinates_deep(raw)
    coordinates = _normalize_route_coordinates(coordinates, req)
    fallback_distance = _distance_m(req.from_lat, req.from_lng, req.to_lat, req.to_lng)
    if distance is None:
        distance = fallback_distance
    if duration is None:
        speed_mps = 1.25 if req.profile == "walking" else 8.0
        duration = distance / speed_mps

    return RouteResponse(
        distance_m=float(distance),
        duration_s=float(duration),
        geometry={
            "type": "LineString",
            "coordinates": coordinates,
            "fallback": len(coordinates) < 2,
            "provider": "2gis",
            "profile": req.profile,
            "raw_2gis": raw,
            "raw_route": route,
            "raw_summary": summary,
        },
    )


def _transport_for_profile(profile: str) -> str:
    if profile == "walking":
        return "pedestrian"
    if profile == "cycling":
        return "bicycle"
    return "car"


@router.get("/places/search")
async def twogis_places_search(
    query: str = Query(..., min_length=1),
    lat: float | None = Query(default=None, ge=-90, le=90),
    lng: float | None = Query(default=None, ge=-180, le=180),
    radius_m: int = Query(default=1000, ge=10, le=40000),
    locale: str = Query(default="ru_RU", min_length=2, max_length=8),
    page_size: int = Query(default=10, ge=1, le=50),
    rich: bool = Query(default=True),
):
    try:
        return await places_search(
            query=query,
            lat=lat,
            lng=lng,
            radius_m=radius_m,
            locale=locale,
            page_size=page_size,
            include_raw=rich,
        )
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/places/{place_id}")
async def twogis_place_details(
    place_id: str,
    locale: str = Query(default="ru_KG", min_length=2, max_length=8),
):
    try:
        item = await place_by_id(place_id=place_id, locale=locale)
        if item is None:
            raise HTTPException(status_code=404, detail="2GIS place not found")
        return item
    except HTTPException:
        raise
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/geocode")
async def twogis_geocode(
    query: str | None = Query(default=None, min_length=1),
    lat: float | None = Query(default=None, ge=-90, le=90),
    lng: float | None = Query(default=None, ge=-180, le=180),
    radius_m: int = Query(default=250, ge=0, le=2000),
    locale: str = Query(default="ru_RU", min_length=2, max_length=8),
):
    try:
        return await geocode(
            query=query,
            lat=lat,
            lng=lng,
            radius_m=radius_m,
            locale=locale,
        )
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/suggest")
async def twogis_suggest(
    query: str = Query(..., min_length=1),
    lat: float | None = Query(default=None, ge=-90, le=90),
    lng: float | None = Query(default=None, ge=-180, le=180),
    locale: str = Query(default="ru_RU", min_length=2, max_length=8),
    suggest_type: str = Query(default="object", min_length=1),
):
    try:
        return await suggest(
            query=query,
            lat=lat,
            lng=lng,
            locale=locale,
            suggest_type=suggest_type,
        )
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/categories/search")
async def twogis_categories_search(
    query: str = Query(..., min_length=1),
    region_id: str = Query(..., min_length=1),
    page_size: int = Query(default=20, ge=1, le=50),
):
    try:
        return await categories_search(
            query=query,
            region_id=region_id,
            page_size=page_size,
        )
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/categories")
async def twogis_categories_list(
    region_id: str = Query(..., min_length=1),
    parent_id: str = Query(default="0"),
):
    try:
        return await categories_list(region_id=region_id, parent_id=parent_id)
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/routing")
async def twogis_routing(
    from_lat: float = Query(..., ge=-90, le=90),
    from_lng: float = Query(..., ge=-180, le=180),
    to_lat: float = Query(..., ge=-90, le=90),
    to_lng: float = Query(..., ge=-180, le=180),
    transport: str = Query(default="driving", min_length=1),
    locale: str = Query(default="ru", min_length=2, max_length=5),
):
    try:
        raw = await routing(
            from_lat=from_lat,
            from_lng=from_lng,
            to_lat=to_lat,
            to_lng=to_lng,
            transport=transport,
            locale=locale,
        )
        return {
            "provider": "2gis",
            "transport": transport,
            "raw_2gis": raw,
        }
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/directions")
async def twogis_directions(
    from_lat: float = Query(..., ge=-90, le=90),
    from_lng: float = Query(..., ge=-180, le=180),
    to_lat: float = Query(..., ge=-90, le=90),
    to_lng: float = Query(..., ge=-180, le=180),
    transport: str = Query(default="driving", min_length=1),
    locale: str = Query(default="ru", min_length=2, max_length=5),
):
    try:
        raw = await routing(
            from_lat=from_lat,
            from_lng=from_lng,
            to_lat=to_lat,
            to_lng=to_lng,
            transport=transport,
            locale=locale,
        )
        return {
            "provider": "2gis",
            "transport": transport,
            "raw_2gis": raw,
        }
    except Exception as e:
        raise _handle_twogis_error(e)


@router.post("/directions", response_model=RouteResponse)
async def twogis_directions_route(
    req: RouteRequest,
    user_id: int = Depends(require_auth),
):
    try:
        if req.profile == "transit":
            raw = await public_transport(
                from_lat=req.from_lat,
                from_lng=req.from_lng,
                to_lat=req.to_lat,
                to_lng=req.to_lng,
                locale="ru",
            )
        else:
            raw = await routing(
                from_lat=req.from_lat,
                from_lng=req.from_lng,
                to_lat=req.to_lat,
                to_lng=req.to_lng,
                transport=_transport_for_profile(req.profile),
                locale="ru",
            )
        route = _route_response_from_2gis(raw, req)
        await save_route_history(user_id, req, route)
        await register_route_built(user_id)
        return route
    except Exception as e:
        raise _handle_twogis_error(e)


@router.post("/tour-route", response_model=RouteResponse)
async def twogis_tour_route(
    payload: TourRouteRequest,
    _user_id: int = Depends(require_auth),
):
    try:
        total_distance = 0.0
        total_duration = 0.0
        all_coordinates: list[list[float]] = []
        points = payload.points
        for index in range(len(points) - 1):
            start = points[index]
            finish = points[index + 1]
            req = RouteRequest(
                from_lat=start.lat,
                from_lng=start.lng,
                to_lat=finish.lat,
                to_lng=finish.lng,
                profile=payload.profile,
                destination_name=f"Tour stop {index + 2}",
            )
            raw = await routing(
                from_lat=req.from_lat,
                from_lng=req.from_lng,
                to_lat=req.to_lat,
                to_lng=req.to_lng,
                transport=_transport_for_profile(req.profile),
                locale="ru",
            )
            segment = _route_response_from_2gis(raw, req)
            coordinates = segment.geometry.get("coordinates")
            if not isinstance(coordinates, list) or len(coordinates) < 2:
                continue
            total_distance += segment.distance_m
            total_duration += segment.duration_s
            if all_coordinates and all_coordinates[-1] == coordinates[0]:
                all_coordinates.extend(coordinates[1:])
            else:
                all_coordinates.extend(coordinates)

        if len(all_coordinates) < 2:
            raise TwoGisError("2GIS did not return tour route geometry")

        return RouteResponse(
            distance_m=total_distance,
            duration_s=total_duration,
            geometry={
                "type": "LineString",
                "coordinates": all_coordinates,
                "fallback": False,
                "provider": "2gis",
                "profile": payload.profile,
            },
        )
    except Exception as e:
        if isinstance(e, TwoGisError):
            return []
        raise _handle_twogis_error(e)


@router.get("/public-transport")
async def twogis_public_transport(
    from_lat: float = Query(..., ge=-90, le=90),
    from_lng: float = Query(..., ge=-180, le=180),
    to_lat: float = Query(..., ge=-90, le=90),
    to_lng: float = Query(..., ge=-180, le=180),
    locale: str = Query(default="ru", min_length=2, max_length=5),
):
    try:
        raw = await public_transport(
            from_lat=from_lat,
            from_lng=from_lng,
            to_lat=to_lat,
            to_lng=to_lng,
            locale=locale,
        )
        return {
            "provider": "2gis",
            "transport": "public_transport",
            "raw_2gis": raw,
        }
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/directions/history", response_model=list[RouteHistoryItem])
async def twogis_route_history(
    limit: int = Query(default=10, ge=1, le=50),
    user_id: int = Depends(require_auth),
):
    try:
        return await list_route_history(user_id, limit=limit)
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/resolve-tap")
async def twogis_resolve_tap(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_m: int = Query(default=80, ge=10, le=300),
    locale: str = Query(default="ru_RU", min_length=2, max_length=8),
):
    try:
        return await resolve_tap(
            lat=lat,
            lng=lng,
            radius_m=radius_m,
            locale=locale,
        )
    except Exception as e:
        if isinstance(e, TwoGisError):
            return []
        raise _handle_twogis_error(e)
