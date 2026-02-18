import re
import secrets
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, Header, File, Form, UploadFile, Request
from app.models.auth import RegisterIn, LoginIn, GoogleAuthIn, AuthOut, AuthMeOut
from app.services.user_repo import (
    get_user_by_email,
    get_user_by_username,
    create_user,
    get_user_by_id,
    is_username_taken_by_other,
    update_user_profile,
)
from app.services.auth_service import create_session, delete_session
from app.services.google_auth import verify_google_id_token, GoogleAuthError
from app.core.security import hash_password, verify_password
from app.deps.auth import require_auth

router = APIRouter(prefix="/api/auth", tags=["auth"])
UPLOADS_DIR = Path(__file__).resolve().parents[2] / "uploads" / "avatars"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

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


def _avatar_public_url(request: Request, avatar_path: str | None) -> str | None:
    if not avatar_path:
        return None
    base = str(request.base_url).rstrip("/")
    return f"{base}{avatar_path}"


@router.get("/me", response_model=AuthMeOut)
async def me(request: Request, user_id: int = Depends(require_auth)):
    user = await get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return AuthMeOut(
        id=user["id"],
        username=user["username"],
        email=user["email"],
        avatar_url=_avatar_public_url(request, user.get("avatar_path")),
    )


@router.patch("/me", response_model=AuthMeOut)
async def update_me(
    request: Request,
    user_id: int = Depends(require_auth),
    username: str | None = Form(default=None),
    password: str | None = Form(default=None),
    avatar: UploadFile | None = File(default=None),
):
    current = await get_user_by_id(user_id)
    if not current:
        raise HTTPException(status_code=404, detail="User not found")

    new_username: str | None = None
    new_password_hash: str | None = None
    new_avatar_path: str | None = None

    if username is not None:
        value = username.strip()
        if len(value) < 3 or len(value) > 20:
            raise HTTPException(status_code=400, detail="Username must be 3-20 chars")
        if not re.match(r"^[a-zA-Z0-9_.-]+$", value):
            raise HTTPException(status_code=400, detail="Invalid username format")
        if await is_username_taken_by_other(user_id, value):
            raise HTTPException(status_code=409, detail="Username already taken")
        new_username = value

    if password is not None:
        value = password.strip()
        if len(value) < 6:
            raise HTTPException(status_code=400, detail="Password must be at least 6 chars")
        new_password_hash = hash_password(value)

    if avatar is not None:
        content_type = (avatar.content_type or "").lower()
        if not content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Avatar must be an image")
        ext = Path(avatar.filename or "avatar.jpg").suffix.lower()
        if ext not in {".jpg", ".jpeg", ".png", ".webp"}:
            ext = ".jpg"
        file_name = f"user_{user_id}_{secrets.token_hex(8)}{ext}"
        target = UPLOADS_DIR / file_name
        data = await avatar.read()
        if len(data) > 5 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="Avatar is too large (max 5MB)")
        target.write_bytes(data)
        new_avatar_path = f"/uploads/avatars/{file_name}"

    updated = await update_user_profile(
        user_id,
        username=new_username,
        password_hash=new_password_hash,
        avatar_path=new_avatar_path,
    )
    return AuthMeOut(
        id=updated["id"],
        username=updated["username"],
        email=updated["email"],
        avatar_url=_avatar_public_url(request, updated.get("avatar_path")),
    )


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
