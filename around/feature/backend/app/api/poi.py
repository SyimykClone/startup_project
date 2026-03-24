from fastapi import APIRouter, Depends, HTTPException
from typing import List
from app.models.poi import CustomPoiFromCoordinatesIn, Poi
from app.services.poi_repo import (
    add_favorite_poi,
    create_custom_poi_from_coordinates,
    get_accessible_poi,
    list_favorite_poi,
    list_poi,
    list_visited_poi,
    mark_poi_visited,
    remove_favorite_poi,
    remove_visited_poi,
)
from app.services.google_maps_service import GoogleMapsError, reverse_geocode
from app.deps.auth import require_auth

router = APIRouter(
    prefix="/api/poi",
    tags=["poi"],
)


@router.get("", response_model=List[Poi])
async def poi_list(_user_id: int = Depends(require_auth)):
    return await list_poi()


@router.get("/favorites", response_model=List[Poi])
async def favorites_list(user_id: int = Depends(require_auth)):
    return await list_favorite_poi(user_id)


@router.post("/favorites/{poi_id}", status_code=204)
async def favorites_add(poi_id: int, user_id: int = Depends(require_auth)):
    poi = await get_accessible_poi(poi_id, user_id)
    if not poi:
        raise HTTPException(status_code=404, detail="POI not found")

    await add_favorite_poi(user_id, poi_id)
    return None


@router.delete("/favorites/{poi_id}", status_code=204)
async def favorites_remove(poi_id: int, user_id: int = Depends(require_auth)):
    removed = await remove_favorite_poi(user_id, poi_id)
    if not removed:
        raise HTTPException(status_code=404, detail="Favorite POI not found")
    return None


@router.get("/visited", response_model=List[Poi])
async def visited_list(user_id: int = Depends(require_auth)):
    return await list_visited_poi(user_id)


@router.post("/visited/{poi_id}", status_code=204)
async def visited_add(poi_id: int, user_id: int = Depends(require_auth)):
    poi = await get_accessible_poi(poi_id, user_id)
    if not poi:
        raise HTTPException(status_code=404, detail="POI not found")

    await mark_poi_visited(user_id, poi_id)
    return None


@router.delete("/visited/{poi_id}", status_code=204)
async def visited_remove(poi_id: int, user_id: int = Depends(require_auth)):
    removed = await remove_visited_poi(user_id, poi_id)
    if not removed:
        raise HTTPException(status_code=404, detail="Visited POI not found")
    return None


@router.get("/{poi_id}", response_model=Poi)
async def poi_detail(poi_id: int, user_id: int = Depends(require_auth)):
    poi = await get_accessible_poi(poi_id, user_id)
    if not poi:
        raise HTTPException(status_code=404, detail="POI not found")
    return poi


@router.post("/custom/from-coordinates", response_model=Poi)
async def poi_create_custom_from_coordinates(
    payload: CustomPoiFromCoordinatesIn,
    user_id: int = Depends(require_auth),
):
    try:
        place = await reverse_geocode(
            lat=payload.lat,
            lng=payload.lng,
            language=payload.language,
        )
        return await create_custom_poi_from_coordinates(
            users_id=user_id,
            name=place["name"],
            description=place["formatted_address"],
            lat=payload.lat,
            lng=payload.lng,
            google_place_id=place.get("place_id"),
        )
    except GoogleMapsError as e:
        raise HTTPException(status_code=400, detail=str(e))
