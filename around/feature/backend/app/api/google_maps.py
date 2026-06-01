from fastapi import APIRouter, Depends, HTTPException, Query, Response
from app.deps.auth import require_auth
from app.models.route import RouteRequest, RouteResponse
from app.services.gamification_repo import register_route_built
from app.services.google_maps_service import (
    GoogleMapsError,
    build_directions,
    fetch_place_photo_media,
    geocode,
    place_details_new,
    places_nearby_new,
    places_search,
    reverse_geocode,
)
from app.services.route_history_repo import list_route_history, save_route_history

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
async def google_directions(req: RouteRequest, user_id: int = Depends(require_auth)):
    try:
        route = await build_directions(req)
        await save_route_history(user_id, req, route)
        await register_route_built(user_id)
        return route
    except GoogleMapsError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")


@router.get("/places/nearby")
async def google_places_nearby(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    place_type: str = Query("tourist_attraction", min_length=1),
    radius_m: int = Query(default=1500, ge=100, le=50000),
    language: str = Query("ru", min_length=2, max_length=5),
):
    try:
        return await places_nearby_new(
            lat=lat,
            lng=lng,
            place_type=place_type,
            radius_m=radius_m,
            language=language,
        )
    except GoogleMapsError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")


@router.get("/places/details/{place_id}")
async def google_place_details(
    place_id: str,
    language: str = Query("ru", min_length=2, max_length=5),
):
    try:
        return await place_details_new(place_id=place_id, language=language)
    except GoogleMapsError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")


@router.get("/places/photo")
async def google_place_photo(
    photo_name: str = Query(..., min_length=1),
    max_width_px: int = Query(default=900, ge=100, le=1600),
):
    try:
        content = await fetch_place_photo_media(
            photo_name=photo_name,
            max_width_px=max_width_px,
        )
        return Response(content=content, media_type="image/jpeg")
    except GoogleMapsError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")


@router.get("/directions/history")
async def google_route_history(
    limit: int = Query(default=10, ge=1, le=50),
    user_id: int = Depends(require_auth),
):
    try:
        return await list_route_history(user_id, limit=limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")
