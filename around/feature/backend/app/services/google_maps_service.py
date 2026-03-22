import httpx
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
    }
    return mapping.get(profile, "walking")


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
