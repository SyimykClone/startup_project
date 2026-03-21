from typing import List, Optional
from app.core.db import get_pool
from app.models.poi import Poi


async def list_poi() -> List[Poi]:
    pool = get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT id, name, description, latitude, longitude, category
            FROM poi
            ORDER BY id
            """
        )
    return [Poi(**dict(r)) for r in rows]


async def get_poi(poi_id: int) -> Optional[Poi]:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            SELECT id, name, description, latitude, longitude, category
            FROM poi
            WHERE id = $1
            """,
            poi_id,
        )
    return Poi(**dict(row)) if row else None


async def list_favorite_poi(users_id: int) -> List[Poi]:
    pool = get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT p.id, p.name, p.description, p.latitude, p.longitude, p.category
            FROM users_favorite_poi fp
            JOIN poi p ON p.id = fp.poi_id
            WHERE fp.users_id = $1
            ORDER BY fp.created_at DESC
            """,
            users_id,
        )
    return [Poi(**dict(r)) for r in rows]


async def add_favorite_poi(users_id: int, poi_id: int) -> None:
    pool = get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            """
            INSERT INTO users_favorite_poi(users_id, poi_id)
            VALUES ($1, $2)
            ON CONFLICT (users_id, poi_id) DO NOTHING
            """,
            users_id,
            poi_id,
        )


async def remove_favorite_poi(users_id: int, poi_id: int) -> bool:
    pool = get_pool()
    async with pool.acquire() as conn:
        result = await conn.execute(
            """
            DELETE FROM users_favorite_poi
            WHERE users_id = $1 AND poi_id = $2
            """,
            users_id,
            poi_id,
        )
    # asyncpg returns: "DELETE <rows_count>"
    return result.endswith(" 1")


async def list_visited_poi(users_id: int) -> List[Poi]:
    pool = get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT p.id, p.name, p.description, p.latitude, p.longitude, p.category
            FROM users_visited_poi vp
            JOIN poi p ON p.id = vp.poi_id
            WHERE vp.users_id = $1
            ORDER BY vp.visited_at DESC
            """,
            users_id,
        )
    return [Poi(**dict(r)) for r in rows]


async def mark_poi_visited(users_id: int, poi_id: int) -> None:
    pool = get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            """
            INSERT INTO users_visited_poi(users_id, poi_id, visited_at)
            VALUES ($1, $2, now())
            ON CONFLICT (users_id, poi_id)
            DO UPDATE SET visited_at = EXCLUDED.visited_at
            """,
            users_id,
            poi_id,
        )
