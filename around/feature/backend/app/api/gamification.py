from fastapi import APIRouter, Depends

from app.deps.auth import require_auth
from app.models.gamification import GamificationMeOut
from app.services.gamification_repo import get_gamification_state

router = APIRouter(prefix="/api/gamification", tags=["gamification"])


@router.get("/me", response_model=GamificationMeOut)
async def gamification_me(user_id: int = Depends(require_auth)):
    return await get_gamification_state(user_id)
