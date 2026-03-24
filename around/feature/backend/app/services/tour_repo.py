from typing import List, Optional
from app.core.db import get_pool
from app.models.tour import Tour


def _tour_from_row(row) -> Tour:
    return Tour(
        id=row["id"],
        business_user_id=row["business_user_id"],
        title=row["title"],
        description=row["description"],
        duration_min=row["duration_min"],
        distance_km=float(row["distance_km"]),
    )


async def list_all_tours() -> List[Tour]:
    pool = get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT id, business_user_id, title, description, duration_min, distance_km
            FROM tours
            ORDER BY id DESC
            """
        )
    return [_tour_from_row(r) for r in rows]


async def list_business_tours(business_user_id: int) -> List[Tour]:
    pool = get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT id, business_user_id, title, description, duration_min, distance_km
            FROM tours
            WHERE business_user_id = $1
            ORDER BY id DESC
            """,
            business_user_id,
        )
    return [_tour_from_row(r) for r in rows]


async def get_tour(tour_id: int) -> Optional[Tour]:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            SELECT id, business_user_id, title, description, duration_min, distance_km
            FROM tours
            WHERE id = $1
            """,
            tour_id,
        )
    return _tour_from_row(row) if row else None


async def create_tour(
    business_user_id: int,
    title: str,
    description: str,
    duration_min: int,
    distance_km: float,
) -> Tour:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            INSERT INTO tours (business_user_id, title, description, duration_min, distance_km)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id, business_user_id, title, description, duration_min, distance_km
            """,
            business_user_id,
            title,
            description,
            duration_min,
            distance_km,
        )
    return _tour_from_row(row)


async def update_tour(
    tour_id: int,
    title: str | None = None,
    description: str | None = None,
    duration_min: int | None = None,
    distance_km: float | None = None,
) -> Optional[Tour]:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            UPDATE tours
            SET
              title = COALESCE($2, title),
              description = COALESCE($3, description),
              duration_min = COALESCE($4, duration_min),
              distance_km = COALESCE($5, distance_km)
            WHERE id = $1
            RETURNING id, business_user_id, title, description, duration_min, distance_km
            """,
            tour_id,
            title,
            description,
            duration_min,
            distance_km,
        )
    return _tour_from_row(row) if row else None


async def delete_tour(tour_id: int) -> bool:
    pool = get_pool()
    async with pool.acquire() as conn:
        result = await conn.execute(
            """
            DELETE FROM tours
            WHERE id = $1
            """,
            tour_id,
        )
    return result.endswith(" 1")
