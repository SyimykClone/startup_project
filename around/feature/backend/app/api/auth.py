import re
import secrets
from fastapi import APIRouter, HTTPException, Header
from app.models.auth import RegisterIn, LoginIn, GoogleAuthIn, AuthOut
from app.services.user_repo import get_user_by_email, get_user_by_username, create_user
from app.services.auth_service import create_session, delete_session
from app.services.google_auth import verify_google_id_token, GoogleAuthError
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


def _normalize_username(value: str) -> str:
    username = re.sub(r"[^a-zA-Z0-9_.-]", "", value)
    if len(username) < 3:
        username = f"user{secrets.randbelow(999999):06d}"
    return username[:20]


async def _unique_username(base: str) -> str:
    candidate = _normalize_username(base)
    if not await get_user_by_username(candidate):
        return candidate

    for _ in range(20):
        suffix = f"{secrets.randbelow(10000):04d}"
        trimmed = candidate[: 20 - len(suffix)]
        alt = f"{trimmed}{suffix}"
        if not await get_user_by_username(alt):
            return alt

    return f"user{secrets.randbelow(999999):06d}"


@router.post("/google", response_model=AuthOut)
async def google_login(data: GoogleAuthIn):
    try:
        payload = verify_google_id_token(data.id_token)
    except GoogleAuthError as e:
        raise HTTPException(status_code=401, detail=str(e))

    email = payload["email"].strip().lower()
    user = await get_user_by_email(email)

    if not user:
        email_local = email.split("@", 1)[0]
        suggested = str(payload.get("name") or email_local)
        username = await _unique_username(suggested)
        user = await create_user(
            username=username,
            email=email,
            password_hash=hash_password(secrets.token_urlsafe(32)),
        )

    token = await create_session(user_id=user["id"])
    return AuthOut(access_token=token)
