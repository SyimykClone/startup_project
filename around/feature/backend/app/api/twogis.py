from fastapi import APIRouter, Depends, HTTPException, Query

from app.deps.auth import require_auth
from app.services.twogis_service import (
    TwoGisError,
    categories_list,
    categories_search,
    geocode,
    places_search,
    public_transport,
    resolve_tap,
    routing,
    suggest,
)

router = APIRouter(
    prefix="/api/2gis",
    tags=["2gis"],
    dependencies=[Depends(require_auth)],
)


def _handle_twogis_error(e: Exception) -> HTTPException:
    if isinstance(e, TwoGisError):
        return HTTPException(status_code=400, detail=str(e))
    return HTTPException(status_code=500, detail=f"Unexpected error: {e}")


@router.get("/places/search")
async def twogis_places_search(
    query: str = Query(..., min_length=1),
    lat: float | None = Query(default=None, ge=-90, le=90),
    lng: float | None = Query(default=None, ge=-180, le=180),
    radius_m: int = Query(default=1000, ge=10, le=40000),
    locale: str = Query(default="ru_RU", min_length=2, max_length=8),
    page_size: int = Query(default=10, ge=1, le=50),
):
    try:
        return await places_search(
            query=query,
            lat=lat,
            lng=lng,
            radius_m=radius_m,
            locale=locale,
            page_size=page_size,
        )
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/geocode")
async def twogis_geocode(
    query: str | None = Query(default=None, min_length=1),
    lat: float | None = Query(default=None, ge=-90, le=90),
    lng: float | None = Query(default=None, ge=-180, le=180),
    radius_m: int = Query(default=250, ge=0, le=2000),
    locale: str = Query(default="ru_RU", min_length=2, max_length=8),
):
    try:
        return await geocode(
            query=query,
            lat=lat,
            lng=lng,
            radius_m=radius_m,
            locale=locale,
        )
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/suggest")
async def twogis_suggest(
    query: str = Query(..., min_length=1),
    lat: float | None = Query(default=None, ge=-90, le=90),
    lng: float | None = Query(default=None, ge=-180, le=180),
    locale: str = Query(default="ru_RU", min_length=2, max_length=8),
    suggest_type: str = Query(default="object", min_length=1),
):
    try:
        return await suggest(
            query=query,
            lat=lat,
            lng=lng,
            locale=locale,
            suggest_type=suggest_type,
        )
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/categories/search")
async def twogis_categories_search(
    query: str = Query(..., min_length=1),
    region_id: str = Query(..., min_length=1),
    page_size: int = Query(default=20, ge=1, le=50),
):
    try:
        return await categories_search(
            query=query,
            region_id=region_id,
            page_size=page_size,
        )
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/categories")
async def twogis_categories_list(
    region_id: str = Query(..., min_length=1),
    parent_id: str = Query(default="0"),
):
    try:
        return await categories_list(region_id=region_id, parent_id=parent_id)
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/routing")
async def twogis_routing(
    from_lat: float = Query(..., ge=-90, le=90),
    from_lng: float = Query(..., ge=-180, le=180),
    to_lat: float = Query(..., ge=-90, le=90),
    to_lng: float = Query(..., ge=-180, le=180),
    transport: str = Query(default="driving", min_length=1),
    locale: str = Query(default="ru", min_length=2, max_length=5),
):
    try:
        return await routing(
            from_lat=from_lat,
            from_lng=from_lng,
            to_lat=to_lat,
            to_lng=to_lng,
            transport=transport,
            locale=locale,
        )
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/directions")
async def twogis_directions(
    from_lat: float = Query(..., ge=-90, le=90),
    from_lng: float = Query(..., ge=-180, le=180),
    to_lat: float = Query(..., ge=-90, le=90),
    to_lng: float = Query(..., ge=-180, le=180),
    transport: str = Query(default="driving", min_length=1),
    locale: str = Query(default="ru", min_length=2, max_length=5),
):
    try:
        return await routing(
            from_lat=from_lat,
            from_lng=from_lng,
            to_lat=to_lat,
            to_lng=to_lng,
            transport=transport,
            locale=locale,
        )
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/public-transport")
async def twogis_public_transport(
    from_lat: float = Query(..., ge=-90, le=90),
    from_lng: float = Query(..., ge=-180, le=180),
    to_lat: float = Query(..., ge=-90, le=90),
    to_lng: float = Query(..., ge=-180, le=180),
    locale: str = Query(default="ru", min_length=2, max_length=5),
):
    try:
        return await public_transport(
            from_lat=from_lat,
            from_lng=from_lng,
            to_lat=to_lat,
            to_lng=to_lng,
            locale=locale,
        )
    except Exception as e:
        raise _handle_twogis_error(e)


@router.get("/resolve-tap")
async def twogis_resolve_tap(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_m: int = Query(default=80, ge=10, le=300),
    locale: str = Query(default="ru_RU", min_length=2, max_length=8),
):
    try:
        return await resolve_tap(
            lat=lat,
            lng=lng,
            radius_m=radius_m,
            locale=locale,
        )
    except Exception as e:
        raise _handle_twogis_error(e)
