import httpx
from app.core.config import settings
from app.models.route import RouteRequest, RouteResponse


class MapboxDirectionsError(Exception):
    pass


async def build_route(req: RouteRequest) -> RouteResponse:
    if not settings.MAPBOX_TOKEN:
        raise MapboxDirectionsError("MAPBOX_TOKEN is not set on backend")

    url = (
        f"https://api.mapbox.com/directions/v5/mapbox/{req.profile}/"
        f"{req.from_lng},{req.from_lat};{req.to_lng},{req.to_lat}"
    )

    params = {
        "geometries": "geojson",  
        "overview": "full",
        "access_token": settings.MAPBOX_TOKEN,
    }

    async with httpx.AsyncClient(timeout=20.0) as client:
        r = await client.get(url, params=params)
        if r.status_code != 200:
            raise MapboxDirectionsError(f"Mapbox error {r.status_code}: {r.text}")

        data = r.json()

    routes = data.get("routes") or []
    if not routes:
        raise MapboxDirectionsError("No routes returned from Mapbox")

    best = routes[0]
    distance = float(best.get("distance", 0.0))  
    duration = float(best.get("duration", 0.0))  
    geometry = best.get("geometry")  

    if not isinstance(geometry, dict) or "coordinates" not in geometry:
        raise MapboxDirectionsError("Invalid geometry from Mapbox")

    return RouteResponse(distance_m=distance, duration_s=duration, geometry=geometry)
