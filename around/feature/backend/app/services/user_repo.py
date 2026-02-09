from typing import Optional
from app.core.db import get_pool

async def get_user_by_email(email: str) -> Optional[dict]:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id, username, email, password_hash FROM users WHERE email=$1",
            email,
        )
    return dict(row) if row else None

async def get_user_by_username(username: str) -> Optional[dict]:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id, username, email, password_hash FROM users WHERE username=$1",
            username,
        )
    return dict(row) if row else None

async def create_user(username: str, email: str, password_hash: str) -> dict:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            INSERT INTO users (username, email, password_hash)
            VALUES ($1, $2, $3)
            RETURNING id, username, email
            """,
            username, email, password_hash,
        )
    return dict(row)
