from fastapi import APIRouter, HTTPException, Header
from app.models.auth import RegisterIn, LoginIn, AuthOut
from app.services.user_repo import get_user_by_email, get_user_by_username, create_user
from app.services.auth_service import create_session, delete_session
from app.core.security import hash_password, verify_password

router = APIRouter(prefix="/api/auth", tags=["auth"])

@router.post("/register", response_model=AuthOut)
async def register(data: RegisterIn):
    if await get_user_by_email(data.email):
        raise HTTPException(status_code=409, detail="Email already registered")
    if await get_user_by_username(data.username):
        raise HTTPException(status_code=409, detail="Username already taken")

    user = await create_user(
        username=data.username.strip(),
        email=data.email.strip().lower(),
        password_hash=hash_password(data.password),
    )
    token = await create_session(user_id=user["id"])
    return AuthOut(access_token=token)

@router.post("/login", response_model=AuthOut)
async def login(data: LoginIn):
    user = await get_user_by_email(data.email.strip().lower())
    if not user or not verify_password(data.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = await create_session(user_id=user["id"])
    return AuthOut(access_token=token)

@router.post("/logout")
async def logout(authorization: str | None = Header(default=None)):
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    token = authorization.split(" ", 1)[1].strip()
    await delete_session(token)
    return {"ok": True}
