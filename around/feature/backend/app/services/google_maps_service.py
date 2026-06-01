import httpx
import re
from app.core.config import settings
from app.models.route import RouteRequest, RouteResponse


class GoogleMapsError(Exception):
    pass


def _require_api_key() -> str:
    key = settings.GOOGLE_SERVER_API_KEY.strip()
    if not key:
        raise GoogleMapsError("GOOGLE_SERVER_API_KEY is not set on backend")
    return key


def _decode_polyline(encoded: str) -> list[tuple[float, float]]:
    points: list[tuple[float, float]] = []
    index = 0
    lat = 0
    lng = 0

    while index < len(encoded):
        shift = 0
        result = 0
        while True:
            b = ord(encoded[index]) - 63
            index += 1
            result |= (b & 0x1F) << shift
            shift += 5
            if b < 0x20:
                break
        dlat = ~(result >> 1) if result & 1 else result >> 1
        lat += dlat

        shift = 0
        result = 0
        while True:
            b = ord(encoded[index]) - 63
            index += 1
            result |= (b & 0x1F) << shift
            shift += 5
            if b < 0x20:
                break
        dlng = ~(result >> 1) if result & 1 else result >> 1
        lng += dlng

        points.append((lat / 1e5, lng / 1e5))

    return points


def _to_google_mode(profile: str) -> str:
    mapping = {
        "walking": "walking",
        "driving": "driving",
        "cycling": "bicycling",
        "transit": "transit",
    }
    return mapping.get(profile, "walking")


def _pick_best_name_from_results(results: list[dict], fallback: str) -> str:
    preferred_types = [
        "point_of_interest",
        "establishment",
        "premise",
        "subpremise",
        "route",
        "neighborhood",
        "locality",
        "administrative_area_level_2",
        "administrative_area_level_1",
        "country",
    ]

    for preferred in preferred_types:
        for result in results:
            for component in result.get("address_components", []):
                types = component.get("types", [])
                name = (component.get("long_name") or "").strip()
                if preferred in types and name:
                    return name

    formatted = (results[0].get("formatted_address") or "").strip() if results else ""
    if formatted:
        first = formatted.split(",")[0].strip()
        if first:
            return first

    return fallback


def _looks_like_code(value: str) -> bool:
    v = value.strip().upper()
    return bool(re.match(r"^[A-Z0-9+\s-]{5,}$", v))


async def geocode(address: str, language: str = "ru") -> dict:
    key = _require_api_key()
    if not address.strip():
        raise GoogleMapsError("address is required")

    url = "https://maps.googleapis.com/maps/api/geocode/json"
    params = {"address": address, "language": language, "key": key}

    async with httpx.AsyncClient(timeout=20.0) as client:
        res = await client.get(url, params=params)
        if res.status_code != 200:
            raise GoogleMapsError(f"Geocoding HTTP error {res.status_code}: {res.text}")
        data = res.json()

    status = data.get("status")
    if status != "OK":
        raise GoogleMapsError(f"Geocoding failed: {status}")

    first = data["results"][0]
    loc = first["geometry"]["location"]
    return {
        "lat": float(loc["lat"]),
        "lng": float(loc["lng"]),
        "formatted_address": first.get("formatted_address"),
        "place_id": first.get("place_id"),
    }


async def reverse_geocode(lat: float, lng: float, language: str = "ru") -> dict:
    key = _require_api_key()

    url = "https://maps.googleapis.com/maps/api/geocode/json"
    params = {
        "latlng": f"{lat},{lng}",
        "language": language,
        "result_type": "street_address|premise|point_of_interest|route|locality",
        "key": key,
    }

    async with httpx.AsyncClient(timeout=20.0) as client:
        res = await client.get(url, params=params)
        if res.status_code != 200:
            raise GoogleMapsError(
                f"Reverse geocoding HTTP error {res.status_code}: {res.text}"
            )
        data = res.json()

    status = data.get("status")
    if status == "ZERO_RESULTS":
        return {
            "lat": lat,
            "lng": lng,
            "name": "Pinned point",
            "formatted_address": f"{lat:.5f}, {lng:.5f}",
            "place_id": None,
        }
    if status != "OK":
        raise GoogleMapsError(f"Reverse geocoding failed: {status}")

    results = data.get("results", [])
    first = results[0]
    plus_code = data.get("plus_code", {}).get("compound_code")
    default_name = "Pinned point"
    name = _pick_best_name_from_results(results, default_name)
    if _looks_like_code(name):
        formatted = (first.get("formatted_address") or "").strip()
        first_part = formatted.split(",")[0].strip() if formatted else ""
        if first_part and not _looks_like_code(first_part):
            name = first_part
        else:
            name = "Pinned point"

    return {
        "lat": lat,
        "lng": lng,
        "name": name,
        "formatted_address": first.get("formatted_address")
        or plus_code
        or f"{lat:.5f}, {lng:.5f}",
        "place_id": first.get("place_id"),
    }


async def places_search(
    query: str,
    lat: float | None = None,
    lng: float | None = None,
    radius_m: int = 3000,
    language: str = "ru",
) -> list[dict]:
    key = _require_api_key()
    if not query.strip():
        raise GoogleMapsError("query is required")

    url = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    params: dict[str, str] = {"query": query, "language": language, "key": key}
    if lat is not None and lng is not None:
        params["location"] = f"{lat},{lng}"
        params["radius"] = str(radius_m)

    async with httpx.AsyncClient(timeout=20.0) as client:
        res = await client.get(url, params=params)
        if res.status_code != 200:
            raise GoogleMapsError(f"Places HTTP error {res.status_code}: {res.text}")
        data = res.json()

    status = data.get("status")
    if status not in ("OK", "ZERO_RESULTS"):
        raise GoogleMapsError(f"Places search failed: {status}")

    results = []
    for item in data.get("results", []):
        loc = item.get("geometry", {}).get("location", {})
        results.append(
            {
                "name": item.get("name"),
                "address": item.get("formatted_address"),
                "place_id": item.get("place_id"),
                "lat": float(loc.get("lat", 0.0)),
                "lng": float(loc.get("lng", 0.0)),
                "rating": item.get("rating"),
            }
        )
    return results


async def places_nearby_new(
    lat: float,
    lng: float,
    place_type: str,
    radius_m: int = 1500,
    language: str = "ru",
) -> list[dict]:
    key = _require_api_key()

    url = "https://places.googleapis.com/v1/places:searchNearby"
    headers = {
        "X-Goog-Api-Key": key,
        "X-Goog-FieldMask": (
            "places.id,places.displayName,places.formattedAddress,"
            "places.location,places.rating,places.types,places.photos"
        ),
    }
    payload = {
        "includedTypes": [place_type],
        "maxResultCount": 12,
        "languageCode": language,
        "locationRestriction": {
            "circle": {
                "center": {"latitude": lat, "longitude": lng},
                "radius": radius_m,
            }
        },
    }

    async with httpx.AsyncClient(timeout=20.0) as client:
        res = await client.post(url, headers=headers, json=payload)
        if res.status_code != 200:
            raise GoogleMapsError(f"Places Nearby New HTTP error {res.status_code}: {res.text}")
        data = res.json()

    results = []
    for item in data.get("places", []):
        loc = item.get("location") or {}
        display_name = item.get("displayName") or {}
        types = item.get("types") or []
        photos = item.get("photos") or []
        first_photo = photos[0].get("name") if photos else None
        results.append(
            {
                "name": display_name.get("text") or "Unnamed place",
                "address": item.get("formattedAddress"),
                "place_id": item.get("id"),
                "lat": float(loc.get("latitude", 0.0)),
                "lng": float(loc.get("longitude", 0.0)),
                "rating": item.get("rating"),
                "category": types[0] if types else place_type,
                "photo_name": first_photo,
            }
        )
    return results


async def place_details_new(place_id: str, language: str = "ru") -> dict:
    key = _require_api_key()
    if not place_id.strip():
        raise GoogleMapsError("place_id is required")

    url = f"https://places.googleapis.com/v1/places/{place_id}"
    headers = {
        "X-Goog-Api-Key": key,
        "X-Goog-FieldMask": (
            "id,displayName,formattedAddress,location,rating,"
            "userRatingCount,types,regularOpeningHours,websiteUri,"
            "nationalPhoneNumber,photos"
        ),
    }
    params = {"languageCode": language}

    async with httpx.AsyncClient(timeout=20.0) as client:
        res = await client.get(url, headers=headers, params=params)
        if res.status_code != 200:
            raise GoogleMapsError(f"Place Details New HTTP error {res.status_code}: {res.text}")
        item = res.json()

    loc = item.get("location") or {}
    display_name = item.get("displayName") or {}
    photos = item.get("photos") or []
    first_photo = photos[0].get("name") if photos else None
    return {
        "name": display_name.get("text") or "Unnamed place",
        "address": item.get("formattedAddress"),
        "place_id": item.get("id"),
        "lat": float(loc.get("latitude", 0.0)),
        "lng": float(loc.get("longitude", 0.0)),
        "rating": item.get("rating"),
        "user_rating_count": item.get("userRatingCount"),
        "types": item.get("types") or [],
        "opening_hours": item.get("regularOpeningHours"),
        "website": item.get("websiteUri"),
        "phone": item.get("nationalPhoneNumber"),
        "photo_name": first_photo,
    }


async def fetch_place_photo_media(photo_name: str, max_width_px: int = 900) -> bytes:
    key = _require_api_key()
    if not photo_name.strip():
        raise GoogleMapsError("photo_name is required")

    url = f"https://places.googleapis.com/v1/{photo_name}/media"
    params = {
        "maxWidthPx": max_width_px,
        "key": key,
    }

    async with httpx.AsyncClient(timeout=20.0, follow_redirects=True) as client:
        res = await client.get(url, params=params)
        if res.status_code != 200:
            raise GoogleMapsError(f"Place photo HTTP error {res.status_code}: {res.text}")
        return res.content


async def build_directions(req: RouteRequest) -> RouteResponse:
    key = _require_api_key()
    mode = _to_google_mode(req.profile)

    url = "https://maps.googleapis.com/maps/api/directions/json"
    params = {
        "origin": f"{req.from_lat},{req.from_lng}",
        "destination": f"{req.to_lat},{req.to_lng}",
        "mode": mode,
        "key": key,
    }

    async with httpx.AsyncClient(timeout=20.0) as client:
        res = await client.get(url, params=params)
        if res.status_code != 200:
            raise GoogleMapsError(f"Directions HTTP error {res.status_code}: {res.text}")
        data = res.json()

    status = data.get("status")
    if status != "OK":
        raise GoogleMapsError(f"Directions failed: {status}")

    route = data["routes"][0]
    leg = route["legs"][0]
    distance = float(leg.get("distance", {}).get("value", 0.0))
    duration = float(leg.get("duration", {}).get("value", 0.0))

    polyline = route.get("overview_polyline", {}).get("points")
    if not polyline:
        raise GoogleMapsError("Directions returned no polyline")

    decoded = _decode_polyline(polyline)
    geometry = {
        "type": "LineString",
        "coordinates": [[lng, lat] for lat, lng in decoded],
    }
    return RouteResponse(distance_m=distance, duration_s=duration, geometry=geometry)
