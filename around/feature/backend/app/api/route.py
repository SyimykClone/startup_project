from fastapi import APIRouter, Depends, HTTPException
from app.models.route import RouteRequest, RouteResponse
from app.services.mapbox_directions import build_route, MapboxDirectionsError
from app.services.gamification_repo import register_route_built
from app.deps.auth import require_auth

router = APIRouter(
    prefix="/api/route",
    tags=["route"],
    dependencies=[Depends(require_auth)],
)


@router.post("", response_model=RouteResponse)
async def route_build(req: RouteRequest, user_id: int = Depends(require_auth)):
    try:
        route = await build_route(req)
        await register_route_built(user_id)
        return route
    except MapboxDirectionsError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")
