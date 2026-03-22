from fastapi import APIRouter, Depends, HTTPException, Query
from app.deps.auth import require_auth
from app.models.route import RouteRequest, RouteResponse
from app.services.google_maps_service import (
    GoogleMapsError,
    build_directions,
    geocode,
    places_search,
    reverse_geocode,
)

router = APIRouter(
    prefix="/api/google",
    tags=["google-maps"],
    dependencies=[Depends(require_auth)],
)


@router.get("/geocode")
async def google_geocode(
    address: str = Query(..., min_length=1),
    language: str = Query("ru", min_length=2, max_length=5),
):
    try:
        return await geocode(address=address, language=language)
    except GoogleMapsError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")


@router.get("/places/search")
async def google_places_search(
    query: str = Query(..., min_length=1),
    lat: float | None = Query(default=None),
    lng: float | None = Query(default=None),
    radius_m: int = Query(default=3000, ge=100, le=50000),
    language: str = Query("ru", min_length=2, max_length=5),
):
    try:
        return await places_search(
            query=query,
            lat=lat,
            lng=lng,
            radius_m=radius_m,
            language=language,
        )
    except GoogleMapsError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")


@router.get("/reverse-geocode")
async def google_reverse_geocode(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    language: str = Query("ru", min_length=2, max_length=5),
):
    try:
        return await reverse_geocode(lat=lat, lng=lng, language=language)
    except GoogleMapsError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")


@router.post("/directions", response_model=RouteResponse)
async def google_directions(req: RouteRequest):
    try:
        return await build_directions(req)
    except GoogleMapsError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")
