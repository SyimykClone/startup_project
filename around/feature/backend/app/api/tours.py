from fastapi import APIRouter, Depends, HTTPException
from typing import List

from app.deps.auth import require_auth
from app.models.tour import Tour, TourCreateIn, TourUpdateIn
from app.services.tour_repo import (
    create_tour,
    delete_tour,
    get_tour,
    list_all_tours,
    list_business_tours,
    update_tour,
)
from app.services.user_repo import get_user_by_id

router = APIRouter(prefix="/api/tours", tags=["tours"])


async def _require_business_user(user_id: int) -> None:
    user = await get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.get("user_type") != "business":
        raise HTTPException(status_code=403, detail="Business role required")


@router.get("", response_model=List[Tour])
async def tours_list(_user_id: int = Depends(require_auth)):
    return await list_all_tours()


@router.get("/mine", response_model=List[Tour])
async def tours_list_mine(user_id: int = Depends(require_auth)):
    await _require_business_user(user_id)
    return await list_business_tours(user_id)


@router.post("", response_model=Tour, status_code=201)
async def tours_create(payload: TourCreateIn, user_id: int = Depends(require_auth)):
    await _require_business_user(user_id)
    return await create_tour(
        business_user_id=user_id,
        title=payload.title.strip(),
        description=payload.description.strip(),
        duration_days=payload.duration_days,
        price=payload.price,
        distance_km=payload.distance_km,
        stops_count=payload.stops_count,
        difficulty=payload.difficulty,
        is_published=payload.is_published,
    )


@router.patch("/{tour_id}", response_model=Tour)
async def tours_update(
    tour_id: int,
    payload: TourUpdateIn,
    user_id: int = Depends(require_auth),
):
    await _require_business_user(user_id)
    tour = await get_tour(tour_id)
    if not tour:
        raise HTTPException(status_code=404, detail="Tour not found")
    if tour.business_user_id != user_id:
        raise HTTPException(status_code=403, detail="Cannot edit another user's tour")

    updated = await update_tour(
        tour_id=tour_id,
        title=payload.title.strip() if payload.title is not None else None,
        description=payload.description.strip()
        if payload.description is not None
        else None,
        duration_days=payload.duration_days,
        price=payload.price,
        distance_km=payload.distance_km,
        stops_count=payload.stops_count,
        difficulty=payload.difficulty,
        is_published=payload.is_published,
    )
    if not updated:
        raise HTTPException(status_code=404, detail="Tour not found")
    return updated


@router.delete("/{tour_id}", status_code=204)
async def tours_delete(tour_id: int, user_id: int = Depends(require_auth)):
    await _require_business_user(user_id)
    tour = await get_tour(tour_id)
    if not tour:
        raise HTTPException(status_code=404, detail="Tour not found")
    if tour.business_user_id != user_id:
        raise HTTPException(
            status_code=403, detail="Cannot delete another user's tour"
        )

    deleted = await delete_tour(tour_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Tour not found")
    return None
