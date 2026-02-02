from fastapi import APIRouter, HTTPException
from typing import List
from app.models.poi import Poi
from app.services.poi_repo import list_poi, get_poi

router = APIRouter(prefix="/api/poi", tags=["poi"])


@router.get("", response_model=List[Poi])
async def poi_list():
    return await list_poi()


@router.get("/{poi_id}", response_model=Poi)
async def poi_detail(poi_id: int):
    poi = await get_poi(poi_id)
    if not poi:
        raise HTTPException(status_code=404, detail="POI not found")
    return poi
