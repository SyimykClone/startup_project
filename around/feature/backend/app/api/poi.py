from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List
from app.models.poi import ArPoiNearby, CustomPoiFromCoordinatesIn, Poi
from app.services.poi_repo import (
    add_favorite_poi,
    create_custom_poi_from_coordinates,
    get_accessible_poi,
    get_nearest_ar_poi,
    list_favorite_poi,
    list_poi,
    list_visited_poi,
    mark_poi_visited,
    remove_favorite_poi,
    remove_visited_poi,
)
from app.services.twogis_service import TwoGisError, geocode
from app.services.gamification_repo import register_new_place_visit
from app.deps.auth import require_auth

router = APIRouter(
    prefix="/api/poi",
    tags=["poi"],
)


def _place_from_twogis_geocode(data: dict, lat: float, lng: float) -> dict:
    items = data.get("result", {}).get("items", []) or []
    if not items:
        return {
            "name": "Selected point",
            "description": f"{lat:.5f}, {lng:.5f}",
            "place_id": None,
        }

    item = items[0]
    name = (
        item.get("name")
        or item.get("full_name")
        or item.get("address_name")
        or "Selected point"
    )
    description = (
        item.get("full_address_name")
        or item.get("address_name")
        or item.get("address_comment")
        or f"{lat:.5f}, {lng:.5f}"
    )
    return {
        "name": str(name),
        "description": str(description),
        "place_id": item.get("id"),
    }


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


@router.get("/ar/nearby", response_model=ArPoiNearby)
async def ar_nearby(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    max_distance_m: int = Query(default=1000, ge=10, le=5000),
    _user_id: int = Depends(require_auth),
):
    poi = await get_nearest_ar_poi(
        lat=lat,
        lng=lng,
        max_distance_m=max_distance_m,
    )
    if not poi:
        raise HTTPException(status_code=404, detail="AR object not found nearby")
    return poi


@router.post("/visited/{poi_id}", status_code=204)
async def visited_add(poi_id: int, user_id: int = Depends(require_auth)):
    poi = await get_accessible_poi(poi_id, user_id)
    if not poi:
        raise HTTPException(status_code=404, detail="POI not found")

    first_visit = await mark_poi_visited(user_id, poi_id)
    if first_visit:
        await register_new_place_visit(user_id)
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
        data = await geocode(
            lat=payload.lat,
            lng=payload.lng,
            locale="ru_KG" if payload.language == "ru" else "en_RU",
        )
        place = _place_from_twogis_geocode(data, payload.lat, payload.lng)
        return await create_custom_poi_from_coordinates(
            users_id=user_id,
            name=place["name"],
            description=place["description"],
            lat=payload.lat,
            lng=payload.lng,
            google_place_id=place.get("place_id"),
        )
    except TwoGisError as e:
        raise HTTPException(status_code=400, detail=str(e))
