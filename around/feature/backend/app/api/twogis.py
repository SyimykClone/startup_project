import math
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query

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
        lat = point.get("lat") or point.get("latitude")
        lng = point.get("lon") or point.get("lng") or point.get("longitude")
        if isinstance(lat, (int, float)) and isinstance(lng, (int, float)):
            return [float(lng), float(lat)]
    if isinstance(point, (list, tuple)) and len(point) >= 2:
        first, second = point[0], point[1]
        if isinstance(first, (int, float)) and isinstance(second, (int, float)):
            return [float(first), float(second)]
    return None


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


def _coordinates_deep(raw: Any) -> list[list[float]]:
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

    coordinates = _extract_coordinates(route)
    if len(coordinates) < 2:
        coordinates = _coordinates_deep(raw)
    if len(coordinates) < 2:
        coordinates = [
            [req.from_lng, req.from_lat],
            [req.to_lng, req.to_lat],
        ]

    fallback_distance = _distance_m(req.from_lat, req.from_lng, req.to_lat, req.to_lng)
    if distance is None:
        distance = fallback_distance
    if duration is None:
        speed_mps = 1.25 if req.profile == "walking" else 8.0
        duration = distance / speed_mps

    return RouteResponse(
        distance_m=float(distance),
        duration_s=float(duration),
        geometry={"type": "LineString", "coordinates": coordinates},
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
):
    try:
        return await places_search(
            query=query,
            lat=lat,
            lng=lng,
            radius_m=radius_m,
            locale=locale,
            page_size=page_size,
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
        return await routing(
            from_lat=from_lat,
            from_lng=from_lng,
            to_lat=to_lat,
            to_lng=to_lng,
            transport=transport,
            locale=locale,
        )
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
        return await routing(
            from_lat=from_lat,
            from_lng=from_lng,
            to_lat=to_lat,
            to_lng=to_lng,
            transport=transport,
            locale=locale,
        )
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


@router.get("/public-transport")
async def twogis_public_transport(
    from_lat: float = Query(..., ge=-90, le=90),
    from_lng: float = Query(..., ge=-180, le=180),
    to_lat: float = Query(..., ge=-90, le=90),
    to_lng: float = Query(..., ge=-180, le=180),
    locale: str = Query(default="ru", min_length=2, max_length=5),
):
    try:
        return await public_transport(
            from_lat=from_lat,
            from_lng=from_lng,
            to_lat=to_lat,
            to_lng=to_lng,
            locale=locale,
        )
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
        raise _handle_twogis_error(e)
