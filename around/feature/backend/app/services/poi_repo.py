from typing import List, Optional
from app.core.db import get_pool
from app.models.poi import Poi


def _poi_from_row(row) -> Poi:
    return Poi(
        id=row["id"],
        name=row["name"],
        description=row["description"],
        latitude=row["latitude"],
        longitude=row["longitude"],
        category=row["category"],
    )


async def list_poi() -> List[Poi]:
    pool = get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT id, name, description, latitude, longitude, category
            FROM poi
            WHERE source = 'seed'
            ORDER BY id
            """
        )
    return [_poi_from_row(r) for r in rows]


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
    return _poi_from_row(row) if row else None


async def get_accessible_poi(poi_id: int, users_id: int) -> Optional[Poi]:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            SELECT id, name, description, latitude, longitude, category
            FROM poi
            WHERE id = $1
              AND (
                source = 'seed'
                OR created_by_users_id = $2
              )
            """,
            poi_id,
            users_id,
        )
    return _poi_from_row(row) if row else None


async def create_custom_poi_from_coordinates(
    users_id: int,
    name: str,
    description: str,
    lat: float,
    lng: float,
    google_place_id: str | None = None,
) -> Poi:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            INSERT INTO poi (
                name,
                description,
                latitude,
                longitude,
                category,
                source,
                created_by_users_id,
                google_place_id
            )
            VALUES (
                $1, $2, $3, $4,
                'custom',
                'custom',
                $5,
                $6
            )
            RETURNING id, name, description, latitude, longitude, category
            """,
            name,
            description,
            lat,
            lng,
            users_id,
            google_place_id,
        )
    return _poi_from_row(row)


async def list_favorite_poi(users_id: int) -> List[Poi]:
    pool = get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT p.id, p.name, p.description, p.latitude, p.longitude, p.category
            FROM users_favorite_poi fp
            JOIN poi p ON p.id = fp.poi_id
            WHERE fp.users_id = $1
              AND (
                p.source = 'seed'
                OR p.created_by_users_id = $1
              )
            ORDER BY fp.created_at DESC
            """,
            users_id,
        )
    return [_poi_from_row(r) for r in rows]


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
              AND (
                p.source = 'seed'
                OR p.created_by_users_id = $1
              )
            ORDER BY vp.visited_at DESC
            """,
            users_id,
        )
    return [_poi_from_row(r) for r in rows]


async def mark_poi_visited(users_id: int, poi_id: int) -> bool:
    pool = get_pool()
    async with pool.acquire() as conn:
        inserted = await conn.fetchval(
            """
            INSERT INTO users_visited_poi(users_id, poi_id)
            VALUES ($1, $2)
            ON CONFLICT (users_id, poi_id) DO NOTHING
            RETURNING 1
            """,
            users_id,
            poi_id,
        )
        if inserted == 1:
            return True
        await conn.execute(
            """
            UPDATE users_visited_poi
            SET visited_at = now()
            WHERE users_id = $1 AND poi_id = $2
            """,
            users_id,
            poi_id,
        )
    return False


async def remove_visited_poi(users_id: int, poi_id: int) -> bool:
    pool = get_pool()
    async with pool.acquire() as conn:
        result = await conn.execute(
            """
            DELETE FROM users_visited_poi
            WHERE users_id = $1 AND poi_id = $2
            """,
            users_id,
            poi_id,
        )
    return result.endswith(" 1")
