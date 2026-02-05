import json
from app.core.redis import get_redis
from app.core.config import settings
from app.core.security import new_session_id

async def create_session(user_id: int) -> str:
    r = get_redis()
    sid = new_session_id()
    key = f"sess:{sid}"
    await r.set(key, json.dumps({"user_id": user_id}), ex=settings.AUTH_SESSION_TTL_SECONDS)
    return sid

async def delete_session(session_id: str) -> None:
    r = get_redis()
    await r.delete(f"sess:{session_id}")
