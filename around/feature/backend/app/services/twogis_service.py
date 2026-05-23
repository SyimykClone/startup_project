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


async def _get_json(url: str, params: dict[str, Any]) -> Any:
    params = {"key": _require_api_key(), **params}
    async with httpx.AsyncClient(timeout=20.0) as client:
        res = await client.get(url, params=params)
    if res.status_code != 200:
        raise TwoGisError(f"2GIS HTTP error {res.status_code}: {res.text}")
    data = res.json()
    if isinstance(data, list):
        return data
    code = data.get("meta", {}).get("code")
    if code is not None and code != 200:
        raise TwoGisError(f"2GIS API failed: {code}")
    return data


async def _post_json(url: str, body: dict[str, Any]) -> Any:
    async with httpx.AsyncClient(timeout=25.0) as client:
        res = await client.post(
            url,
            params={"key": _require_api_key()},
            json=body,
        )
    if res.status_code != 200:
        raise TwoGisError(f"2GIS HTTP error {res.status_code}: {res.text}")
    data = res.json()
    if isinstance(data, list):
        return data
    status = data.get("status")
    code = data.get("meta", {}).get("code")
    if code is not None and code != 200:
        raise TwoGisError(f"2GIS API failed: {code}")
    if status not in (None, "OK"):
        raise TwoGisError(f"2GIS API failed: {status}")
    return data


def _items_from_response(data: Any) -> list[dict]:
    if isinstance(data, list):
        return [item for item in data if isinstance(item, dict)]
    if not isinstance(data, dict):
        return []

    result = data.get("result")
    if isinstance(result, list):
        return [item for item in result if isinstance(item, dict)]
    if isinstance(result, dict):
        items = result.get("items") or result.get("objects") or []
        if isinstance(items, list):
            return [item for item in items if isinstance(item, dict)]

    items = data.get("items") or []
    if isinstance(items, list):
        return [item for item in items if isinstance(item, dict)]
    return []


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


TWOGIS_DETAIL_FIELDS = (
    "items.point,items.address,items.address_name,items.full_address_name,"
    "items.rubrics,items.description,items.summary,items.reviews,"
    "items.external_content,items.photos,items.flags"
)

SAFE_RESOLVE_TAP_QUERIES = (
    "\u043c\u0430\u0433\u0430\u0437\u0438\u043d",
    "\u043a\u0430\u0444\u0435",
    "\u0440\u0435\u0441\u0442\u043e\u0440\u0430\u043d",
    "\u0430\u043f\u0442\u0435\u043a\u0430",
    "\u0431\u0430\u043d\u043a",
    "\u043e\u0442\u0435\u043b\u044c",
    "\u043c\u0443\u0437\u0435\u0439",
    "\u043f\u0430\u0440\u043a",
    "\u0441\u0443\u043f\u0435\u0440\u043c\u0430\u0440\u043a\u0435\u0442",
)


def _extract_photo_url(item: dict) -> str | None:
    for photo in item.get("photos") or []:
        if not isinstance(photo, dict):
            continue
        for key in ("url", "photo_url", "image_url", "preview_url"):
            value = photo.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip().replace("http://", "https://")
        urls = photo.get("urls")
        if isinstance(urls, dict):
            for value in urls.values():
                if isinstance(value, str) and value.strip():
                    return value.strip().replace("http://", "https://")

    for content in item.get("external_content") or []:
        if isinstance(content, dict):
            for key in ("main_photo_url", "photo_url", "url", "image_url"):
                photo_url = content.get(key)
                if isinstance(photo_url, str) and photo_url.strip():
                    return photo_url.strip().replace("http://", "https://")
    return None


def _extract_rating(item: dict) -> float | None:
    reviews = item.get("reviews") or {}
    value = (
        reviews.get("general_rating")
        or reviews.get("org_rating")
        or reviews.get("rating")
    )
    if value is None:
        return None
    try:
        return round(float(value), 1)
    except (TypeError, ValueError):
        return None


def _extract_description(item: dict, category: str, address: str) -> str:
    summary = item.get("summary") or {}
    summary_text = summary.get("text") if isinstance(summary, dict) else None
    description = item.get("description")
    for value in (summary_text, description, category, address):
        if isinstance(value, str) and value.strip():
            return value.strip()
    return ""


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
    address = (
        item.get("address_name")
        or item.get("full_address_name")
        or item.get("address_comment")
        or ""
    )

    normalized = {
        "id": item.get("id"),
        "name": name,
        "address": address,
        "description": _extract_description(item, category, address),
        "lat": float(item_lat),
        "lng": float(item_lng),
        "category": category,
        "rating": _extract_rating(item),
        "photo_url": _extract_photo_url(item),
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
        "fields": TWOGIS_DETAIL_FIELDS,
        "search_nearby": "true",
    }
    if lat is not None and lng is not None:
        params["location"] = f"{lng},{lat}"
        params["radius"] = radius_m
    data = await _get_json(f"{CATALOG_BASE_URL}/3.0/items", params)
    items = _items_from_response(data)
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
        "fields": TWOGIS_DETAIL_FIELDS,
    }
    if query:
        params["q"] = query
    if lat is not None and lng is not None:
        params["lat"] = lat
        params["lon"] = lng
    return await _get_json(f"{CATALOG_BASE_URL}/3.0/items/geocode", params)


async def place_by_id(place_id: str, locale: str = "ru_KG") -> dict | None:
    data = await _get_json(
        f"{CATALOG_BASE_URL}/3.0/items/byid",
        {
            "id": place_id,
            "locale": locale,
            "fields": TWOGIS_DETAIL_FIELDS,
        },
    )
    items = _items_from_response(data)
    if not items:
        return None
    return _normalize_item(items[0])


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
    queries = [
        "магазин",
        "кафе",
        "ресторан",
        "аптека",
        "банк",
        "отель",
        "музей",
        "парк",
        "супермаркет",
    ]
    results_by_id: dict[str, dict] = {}

    for query in SAFE_RESOLVE_TAP_QUERIES:
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

    detailed_results = []
    for item in results_by_id.values():
        item_id = item.get("id")
        if item_id:
            try:
                detailed = await place_by_id(str(item_id), locale=locale)
                if detailed:
                    detailed["distance_m"] = item.get("distance_m")
                    item = {**item, **detailed}
            except TwoGisError:
                pass
        detailed_results.append(item)

    results = sorted(detailed_results, key=lambda item: item["distance_m"])
    return results[:5]
