import math
from typing import Any

import httpx

from app.core.config import settings


class TwoGisError(Exception):
    pass


CATALOG_BASE_URL = "https://catalog.api.2gis.com"
ROUTING_BASE_URL = "https://routing.api.2gis.com"


def _require_api_key() -> str:
    key = settings.TWOGIS_API_KEY.strip()
    if not key:
        raise TwoGisError("TWOGIS_API_KEY is not set on backend")
    return key


async def _get_json(url: str, params: dict[str, Any]) -> dict:
    params = {"key": _require_api_key(), **params}
    async with httpx.AsyncClient(timeout=20.0) as client:
        res = await client.get(url, params=params)
    if res.status_code != 200:
        raise TwoGisError(f"2GIS HTTP error {res.status_code}: {res.text}")
    data = res.json()
    code = data.get("meta", {}).get("code")
    if code is not None and code != 200:
        raise TwoGisError(f"2GIS API failed: {code}")
    return data


async def _post_json(url: str, body: dict[str, Any]) -> dict:
    async with httpx.AsyncClient(timeout=25.0) as client:
        res = await client.post(
            url,
            params={"key": _require_api_key()},
            json=body,
        )
    if res.status_code != 200:
        raise TwoGisError(f"2GIS HTTP error {res.status_code}: {res.text}")
    data = res.json()
    status = data.get("status")
    code = data.get("meta", {}).get("code")
    if code is not None and code != 200:
        raise TwoGisError(f"2GIS API failed: {code}")
    if status not in (None, "OK"):
        raise TwoGisError(f"2GIS API failed: {status}")
    return data


def _distance_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    radius = 6371000.0
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    r_lat1 = math.radians(lat1)
    r_lat2 = math.radians(lat2)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(r_lat1) * math.cos(r_lat2) * math.sin(d_lng / 2) ** 2
    )
    return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _is_clean_name(name: str) -> bool:
    lowered = name.strip().lower()
    if not lowered:
        return False
    blocked = (
        "\u0441\u043e\u0441\u0430\u043b",
        "\u0441\u043e\u0441\u0430\u0442\u044c",
        "\u0445\u0443\u0439",
        "\u043f\u0438\u0437\u0434",
        "\u0435\u0431\u0430",
        "\u0451\u0431\u0430",
        "\u0431\u043b\u044f",
        "\u0441\u0443\u043a\u0430",
        "fuck",
        "shit",
    )
    return not any(fragment in lowered for fragment in blocked)


def _normalize_item(item: dict, lat: float | None = None, lng: float | None = None) -> dict | None:
    point = item.get("point") or {}
    item_lat = point.get("lat")
    item_lng = point.get("lon") or point.get("lng")
    name = (item.get("name") or item.get("full_name") or "").strip()
    if item_lat is None or item_lng is None or not _is_clean_name(name):
        return None

    rubrics = item.get("rubrics") or []
    category = item.get("type") or "place"
    if rubrics and isinstance(rubrics[0], dict):
        category = rubrics[0].get("name") or category

    normalized = {
        "id": item.get("id"),
        "name": name,
        "address": item.get("address_name") or item.get("address_comment") or "",
        "lat": float(item_lat),
        "lng": float(item_lng),
        "category": category,
        "source": "2gis",
    }
    if lat is not None and lng is not None:
        normalized["distance_m"] = round(
            _distance_m(lat, lng, normalized["lat"], normalized["lng"]),
            1,
        )
    return normalized


async def places_search(
    query: str,
    lat: float | None = None,
    lng: float | None = None,
    radius_m: int = 1000,
    locale: str = "ru_RU",
    page_size: int = 10,
) -> list[dict]:
    params: dict[str, Any] = {
        "q": query,
        "locale": locale,
        "page_size": page_size,
        "fields": "items.point,items.address_name,items.rubrics",
    }
    if lat is not None and lng is not None:
        params["location"] = f"{lng},{lat}"
        params["radius"] = radius_m
    data = await _get_json(f"{CATALOG_BASE_URL}/3.0/items", params)
    items = data.get("result", {}).get("items", []) or []
    return [
        normalized
        for item in items
        if (normalized := _normalize_item(item, lat=lat, lng=lng)) is not None
    ]


async def geocode(
    lat: float | None = None,
    lng: float | None = None,
    query: str | None = None,
    radius_m: int = 250,
    locale: str = "ru_RU",
) -> dict:
    params: dict[str, Any] = {
        "locale": locale,
        "radius": radius_m,
        "fields": "items.point,items.address_name,items.rubrics",
    }
    if query:
        params["q"] = query
    if lat is not None and lng is not None:
        params["lat"] = lat
        params["lon"] = lng
    return await _get_json(f"{CATALOG_BASE_URL}/3.0/items/geocode", params)


async def suggest(
    query: str,
    lat: float | None = None,
    lng: float | None = None,
    locale: str = "ru_RU",
    suggest_type: str = "object",
) -> dict:
    params: dict[str, Any] = {
        "q": query,
        "locale": locale,
        "type": suggest_type,
    }
    if lat is not None and lng is not None:
        params["location"] = f"{lng},{lat}"
    return await _get_json(f"{CATALOG_BASE_URL}/3.0/suggests", params)


async def categories_search(query: str, region_id: str, page_size: int = 20) -> dict:
    return await _get_json(
        f"{CATALOG_BASE_URL}/2.0/catalog/rubric/search",
        {"q": query, "region_id": region_id, "page_size": page_size},
    )


async def categories_list(region_id: str, parent_id: str = "0") -> dict:
    return await _get_json(
        f"{CATALOG_BASE_URL}/2.0/catalog/rubric/list",
        {"region_id": region_id, "parent_id": parent_id},
    )


async def routing(
    from_lat: float,
    from_lng: float,
    to_lat: float,
    to_lng: float,
    transport: str = "driving",
    locale: str = "ru",
) -> dict:
    body = {
        "points": [
            {"type": "stop", "lon": from_lng, "lat": from_lat},
            {"type": "stop", "lon": to_lng, "lat": to_lat},
        ],
        "transport": transport,
        "route_mode": "fastest",
        "traffic_mode": "jam",
        "locale": locale,
    }
    return await _post_json(f"{ROUTING_BASE_URL}/routing/7.0.0/global", body)


async def public_transport(
    from_lat: float,
    from_lng: float,
    to_lat: float,
    to_lng: float,
    locale: str = "ru",
) -> dict:
    body = {
        "source": {"point": {"lat": from_lat, "lon": from_lng}},
        "target": {"point": {"lat": to_lat, "lon": to_lng}},
        "transport": ["pedestrian", "bus", "trolleybus", "shuttle_bus", "tram"],
        "locale": locale,
        "enable_schedule": True,
    }
    return await _post_json(f"{ROUTING_BASE_URL}/public_transport/2.0", body)


async def resolve_tap(lat: float, lng: float, radius_m: int = 80, locale: str = "ru_RU") -> list[dict]:
    queries = ["store", "cafe", "restaurant", "pharmacy", "bank", "hotel", "museum", "park"]
    results_by_id: dict[str, dict] = {}

    for query in queries:
        items = await places_search(
            query=query,
            lat=lat,
            lng=lng,
            radius_m=radius_m,
            locale=locale,
            page_size=5,
        )
        for item in items:
            if item.get("distance_m", radius_m + 1) > radius_m:
                continue
            item_id = str(item.get("id") or item["name"])
            results_by_id[item_id] = item

    results = sorted(results_by_id.values(), key=lambda item: item["distance_m"])
    return results[:5]
