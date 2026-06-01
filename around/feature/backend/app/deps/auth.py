from fastapi import Header, HTTPException
from app.services.auth_service import get_session_user_id


async def require_auth(authorization: str | None = Header(default=None)) -> int:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")

    token = authorization.split(" ", 1)[1].strip()
    user_id = await get_session_user_id(token)
    if user_id is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    return user_id
