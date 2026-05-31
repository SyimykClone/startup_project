import math
from typing import Any

import httpx

from app.core.config import settings


class TwoGisError(Exception):
    pass


CATALOG_BASE_URL = "https://catalog.api.2gis.com"
ROUTING_BASE_URL = "https://routing.api.2gis.com"

TWOGIS_SEARCH_FIELDS = (
    "items.id,items.name,items.full_name,items.type,items.subtype,"
    "items.point,items.address_name,items.full_address_name,items.rubrics"
)


def _require_api_key() -> str:
    key = settings.TWOGIS_API_KEY.strip()
    if not key:
        raise TwoGisError("TWOGIS_API_KEY is not set on backend")
    return key


def _safe_locale(locale: Any) -> str:
    value = str(locale or "").lower()
    if value.startswith("en"):
        return "en_US"
    return "ru_RU"


def _normalize_params(params: dict[str, Any]) -> dict[str, Any]:
    normalized = dict(params)
    if "locale" in normalized:
        normalized["locale"] = _safe_locale(normalized["locale"])
    return normalized


async def _get_json(url: str, params: dict[str, Any]) -> Any:
    params = {"key": _require_api_key(), **_normalize_params(params)}
    headers = {"User-Agent": "around-backend/1.0"}
    async with httpx.AsyncClient(timeout=20.0, headers=headers) as client:
        res = await client.get(url, params=params)
        if res.status_code == 400 and "fields" in params:
            safe_params = {
                **params,
                "fields": TWOGIS_SEARCH_FIELDS,
            }
            res = await client.get(url, params=safe_params)
        if res.status_code == 400:
            minimal_params = {
                key: value
                for key, value in params.items()
                if key not in {"fields", "search_nearby"}
            }
            res = await client.get(url, params=minimal_params)
    if res.status_code != 200:
        raise TwoGisError(f"2GIS HTTP error {res.status_code}: {res.text}")
    data = res.json()
    if isinstance(data, list):
        return data
    code = data.get("meta", {}).get("code")
    if code is not None and code != 200:
        async with httpx.AsyncClient(timeout=20.0) as client:
            retry_params = {
                key: value
                for key, value in params.items()
                if key not in {"fields", "search_nearby"}
            }
            retry_res = await client.get(url, params=retry_params)
        if retry_res.status_code != 200:
            raise TwoGisError(f"2GIS HTTP error {retry_res.status_code}: {retry_res.text}")
        retry_data = retry_res.json()
        if isinstance(retry_data, list):
            return retry_data
        retry_code = retry_data.get("meta", {}).get("code")
        if retry_code is not None and retry_code != 200:
            raise TwoGisError(f"2GIS API failed: {retry_code}")
        return retry_data
    return data


async def _post_json(url: str, body: dict[str, Any]) -> Any:
    body = _normalize_params(body)
    headers = {"User-Agent": "around-backend/1.0"}
    async with httpx.AsyncClient(timeout=25.0, headers=headers) as client:
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
    "items.address_comment,items.adm_div,items.geometry.centroid,"
    "items.geometry.hover,items.geometry.selection,items.rubrics,items.org,"
    "items.brand,items.description,items.summary,items.reviews,"
    "items.external_content,items.photos,items.flags,items.contact_groups,"
    "items.schedule,items.schedule_special,items.links,items.ads,"
    "items.access,items.access_comment,items.capacity,items.floors,"
    "items.floor_plans,items.employees_org_count,items.itin,"
    "items.trade_license,items.fias_code,items.fns_code,items.okato,"
    "items.search_attributes.segment_id"
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
    photos = _extract_photo_urls(item)
    return photos[0] if photos else None


def _extract_photo_urls(item: dict) -> list[str]:
    urls: list[str] = []
    for photo in item.get("photos") or []:
        if not isinstance(photo, dict):
            continue
        for key in ("url", "photo_url", "image_url", "preview_url"):
            value = photo.get(key)
            if isinstance(value, str) and value.strip():
                urls.append(value.strip().replace("http://", "https://"))
        photo_urls = photo.get("urls")
        if isinstance(photo_urls, dict):
            for value in photo_urls.values():
                if isinstance(value, str) and value.strip():
                    urls.append(value.strip().replace("http://", "https://"))

    for content in item.get("external_content") or []:
        if isinstance(content, dict):
            for key in ("main_photo_url", "photo_url", "url", "image_url"):
                photo_url = content.get(key)
                if isinstance(photo_url, str) and photo_url.strip():
                    urls.append(photo_url.strip().replace("http://", "https://"))
    return list(dict.fromkeys(urls))


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


def _extract_reviews_count(item: dict) -> int | None:
    reviews = item.get("reviews") or {}
    for key in (
        "review_count",
        "org_review_count",
        "org_review_count_with_stars",
        "items_count",
        "count",
        "reviews_count",
    ):
        value = reviews.get(key)
        if isinstance(value, int):
            return value
        if isinstance(value, str) and value.isdigit():
            return int(value)
    return None


def _extract_contacts(item: dict) -> dict[str, list[str]]:
    contacts: dict[str, list[str]] = {}
    for group in item.get("contact_groups") or []:
        if not isinstance(group, dict):
            continue
        for contact in group.get("contacts") or []:
            if not isinstance(contact, dict):
                continue
            contact_type = str(contact.get("type") or "other")
            value = contact.get("value") or contact.get("text")
            if not isinstance(value, str) or not value.strip():
                continue
            contacts.setdefault(contact_type, []).append(value.strip())
    return {
        key: list(dict.fromkeys(values))
        for key, values in contacts.items()
        if values
    }


def _extract_contact(item: dict, contact_type: str) -> str | None:
    values = _extract_contacts(item).get(contact_type) or []
    return values[0] if values else None


def _extract_site(item: dict) -> str | None:
    sites = _extract_websites(item)
    return sites[0] if sites else None


def _extract_websites(item: dict) -> list[str]:
    sites = _extract_contacts(item).get("website") or []
    for link in item.get("links") or []:
        if not isinstance(link, dict):
            continue
        value = link.get("url") or link.get("href")
        if isinstance(value, str) and value.strip():
            sites.append(value.strip())
    return list(dict.fromkeys(sites))


def _extract_schedule_status(item: dict) -> str | None:
    schedule = item.get("schedule")
    if not isinstance(schedule, dict):
        return None
    for key in ("status", "open_now", "description"):
        value = schedule.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
        if isinstance(value, bool):
            return "open" if value else "closed"
    return None


def _extract_rubrics(item: dict) -> list[dict]:
    return [
        rubric
        for rubric in item.get("rubrics") or []
        if isinstance(rubric, dict)
    ]


def _extract_rubric_names(item: dict) -> list[str]:
    names = []
    for rubric in _extract_rubrics(item):
        name = rubric.get("name")
        if isinstance(name, str) and name.strip():
            names.append(name.strip())
    return names


def _extract_point(point: dict) -> dict[str, float] | None:
    lat = point.get("lat")
    lng = point.get("lon") or point.get("lng")
    if isinstance(lat, (int, float)) and isinstance(lng, (int, float)):
        return {"lat": float(lat), "lng": float(lng)}
    return None


def _extract_contacts_flat(item: dict, contact_type: str) -> list[str]:
    return _extract_contacts(item).get(contact_type) or []


def _extract_description(item: dict, category: str, address: str) -> str:
    summary = item.get("summary") or {}
    summary_text = summary.get("text") if isinstance(summary, dict) else None
    description = item.get("description")
    for value in (summary_text, description, category, address):
        if isinstance(value, str) and value.strip():
            return value.strip()
    return ""


def _normalize_item(
    item: dict,
    lat: float | None = None,
    lng: float | None = None,
    include_raw: bool = False,
) -> dict | None:
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
    contacts = _extract_contacts(item)
    photos = _extract_photo_urls(item)
    search_attributes = item.get("search_attributes") or {}

    normalized = {
        "id": item.get("id"),
        "provider": "2gis",
        "provider_place_id": item.get("id"),
        "name": name,
        "full_name": item.get("full_name") or name,
        "type": item.get("type"),
        "subtype": item.get("subtype"),
        "purpose_name": item.get("purpose_name"),
        "region_id": item.get("region_id"),
        "segment_id": item.get("segment_id") or search_attributes.get("segment_id"),
        "address": address,
        "full_address": item.get("full_address_name") or address,
        "address_comment": item.get("address_comment"),
        "adm_div": item.get("adm_div"),
        "description": _extract_description(item, category, address),
        "lat": float(item_lat),
        "lng": float(item_lng),
        "point": _extract_point(point),
        "geometry": item.get("geometry"),
        "category": category,
        "rubrics": _extract_rubrics(item),
        "rubric_names": _extract_rubric_names(item),
        "rating": _extract_rating(item),
        "reviews_count": _extract_reviews_count(item),
        "reviews": item.get("reviews"),
        "photo_url": photos[0] if photos else None,
        "photo_urls": photos,
        "photos": item.get("photos") or [],
        "phone": _extract_contact(item, "phone"),
        "phones": _extract_contacts_flat(item, "phone"),
        "email": _extract_contact(item, "email"),
        "emails": _extract_contacts_flat(item, "email"),
        "website": _extract_site(item),
        "websites": _extract_websites(item),
        "contacts": contacts,
        "schedule_status": _extract_schedule_status(item),
        "schedule": item.get("schedule"),
        "schedule_special": item.get("schedule_special"),
        "flags": item.get("flags") or [],
        "org": item.get("org"),
        "brand": item.get("brand"),
        "links": item.get("links") or [],
        "external_content": item.get("external_content") or [],
        "ads": item.get("ads"),
        "access": item.get("access"),
        "access_comment": item.get("access_comment"),
        "capacity": item.get("capacity"),
        "floors": item.get("floors"),
        "floor_plans": item.get("floor_plans"),
        "employees_org_count": item.get("employees_org_count"),
        "itin": item.get("itin"),
        "trade_license": item.get("trade_license"),
        "fias_code": item.get("fias_code"),
        "fns_code": item.get("fns_code"),
        "okato": item.get("okato"),
        "source": "2gis",
    }
    if lat is not None and lng is not None:
        normalized["distance_m"] = round(
            _distance_m(lat, lng, normalized["lat"], normalized["lng"]),
            1,
        )
    if include_raw:
        normalized["raw_2gis"] = item
    return normalized


async def places_search(
    query: str,
    lat: float | None = None,
    lng: float | None = None,
    radius_m: int = 1000,
    locale: str = "ru_RU",
    page_size: int = 10,
    include_raw: bool = True,
) -> list[dict]:
    params: dict[str, Any] = {
        "q": query,
        "locale": locale,
        "page_size": page_size,
        "fields": TWOGIS_SEARCH_FIELDS,
    }
    if lat is not None and lng is not None:
        params["location"] = f"{lng},{lat}"
        params["radius"] = radius_m
    data = await _get_json(f"{CATALOG_BASE_URL}/3.0/items", params)
    items = _items_from_response(data)
    return [
        normalized
        for item in items
        if (
            normalized := _normalize_item(
                item,
                lat=lat,
                lng=lng,
                include_raw=include_raw,
            )
        )
        is not None
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


async def objects_near_point(
    lat: float,
    lng: float,
    radius_m: int = 80,
    locale: str = "ru_RU",
    page_size: int = 10,
) -> list[dict]:
    data = await _get_json(
        f"{CATALOG_BASE_URL}/3.0/items/geocode",
        {
            "lat": lat,
            "lon": lng,
            "radius": radius_m,
            "locale": locale,
            "fields": TWOGIS_SEARCH_FIELDS,
        },
    )
    items = _items_from_response(data)
    results = [
        normalized
        for item in items
        if (
            normalized := _normalize_item(
                item,
                lat=lat,
                lng=lng,
                include_raw=True,
            )
        )
        is not None
    ]
    return sorted(results, key=lambda item: item.get("distance_m", radius_m + 1))


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
    return _normalize_item(items[0], include_raw=True)


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
        "output": "detailed",
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

    try:
        for item in await objects_near_point(
            lat=lat,
            lng=lng,
            radius_m=radius_m,
            locale=locale,
            page_size=10,
        ):
            if item.get("distance_m", radius_m + 1) > radius_m:
                continue
            item_id = str(item.get("id") or item["name"])
            results_by_id[item_id] = item
    except TwoGisError:
        pass

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
