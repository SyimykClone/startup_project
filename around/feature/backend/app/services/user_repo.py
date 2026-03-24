from typing import Optional
from app.core.db import get_pool

async def get_user_by_email(email: str) -> Optional[dict]:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id, username, email, password_hash, user_type FROM users WHERE email=$1",
            email,
        )
    return dict(row) if row else None

async def get_user_by_username(username: str) -> Optional[dict]:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id, username, email, password_hash, user_type FROM users WHERE username=$1",
            username,
        )
    return dict(row) if row else None

async def create_user(
    username: str,
    email: str,
    password_hash: str,
    user_type: str = "user",
) -> dict:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            INSERT INTO users (username, email, password_hash, user_type)
            VALUES ($1, $2, $3, $4)
            RETURNING id, username, email, user_type
            """,
            username, email, password_hash, user_type,
        )
    return dict(row)


async def get_user_by_id(user_id: int) -> Optional[dict]:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id, username, email, avatar_path, user_type FROM users WHERE id=$1",
            user_id,
        )
    return dict(row) if row else None


async def is_username_taken_by_other(user_id: int, username: str) -> bool:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id FROM users WHERE username=$1 AND id<>$2",
            username,
            user_id,
        )
    return row is not None


async def update_user_profile(
    user_id: int,
    *,
    username: str | None = None,
    password_hash: str | None = None,
    avatar_path: str | None = None,
) -> dict:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            UPDATE users
            SET
              username = COALESCE($2, username),
              password_hash = COALESCE($3, password_hash),
              avatar_path = COALESCE($4, avatar_path)
            WHERE id = $1
            RETURNING id, username, email, avatar_path, user_type
            """,
            user_id,
            username,
            password_hash,
            avatar_path,
        )
    return dict(row)
