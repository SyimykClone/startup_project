from typing import List, Optional
from app.core.db import get_pool
from app.models.tour import Tour


def _tour_from_row(row) -> Tour:
    return Tour(
        id=row["id"],
        business_user_id=row["business_user_id"],
        title=row["title"],
        description=row["description"],
        duration_days=row["duration_days"],
        price=float(row["price"]),
        distance_km=float(row["distance_km"]),
        stops_count=row["stops_count"],
        difficulty=row["difficulty"],
        is_published=row["is_published"],
    )


async def list_all_tours() -> List[Tour]:
    pool = get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT id, business_user_id, title, description,
                   duration_days, price, distance_km,
                   stops_count, difficulty, is_published
            FROM tours
            WHERE is_published = TRUE
            ORDER BY updated_at DESC, id DESC
            """
        )
    return [_tour_from_row(r) for r in rows]


async def list_business_tours(business_user_id: int) -> List[Tour]:
    pool = get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT id, business_user_id, title, description,
                   duration_days, price, distance_km,
                   stops_count, difficulty, is_published
            FROM tours
            WHERE business_user_id = $1
            ORDER BY updated_at DESC, id DESC
            """,
            business_user_id,
        )
    return [_tour_from_row(r) for r in rows]


async def get_tour(tour_id: int) -> Optional[Tour]:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            SELECT id, business_user_id, title, description,
                   duration_days, price, distance_km,
                   stops_count, difficulty, is_published
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
    duration_days: int,
    price: float,
    distance_km: float,
    stops_count: int,
    difficulty: str,
    is_published: bool,
) -> Tour:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            INSERT INTO tours (
                business_user_id, title, description, duration_days, price,
                distance_km, stops_count, difficulty, is_published
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING id, business_user_id, title, description, duration_days, price, distance_km,
                      stops_count, difficulty, is_published
            """,
            business_user_id,
            title,
            description,
            duration_days,
            price,
            distance_km,
            stops_count,
            difficulty,
            is_published,
        )
    return _tour_from_row(row)


async def update_tour(
    tour_id: int,
    title: str | None = None,
    description: str | None = None,
    duration_days: int | None = None,
    price: float | None = None,
    distance_km: float | None = None,
    stops_count: int | None = None,
    difficulty: str | None = None,
    is_published: bool | None = None,
) -> Optional[Tour]:
    pool = get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            UPDATE tours
            SET
              title = COALESCE($2, title),
              description = COALESCE($3, description),
              duration_days = COALESCE($4, duration_days),
              price = COALESCE($5, price),
              distance_km = COALESCE($6, distance_km),
              stops_count = COALESCE($7, stops_count),
              difficulty = COALESCE($8, difficulty),
              is_published = COALESCE($9, is_published),
              updated_at = now()
            WHERE id = $1
            RETURNING id, business_user_id, title, description, duration_days, price, distance_km,
                      stops_count, difficulty, is_published
            """,
            tour_id,
            title,
            description,
            duration_days,
            price,
            distance_km,
            stops_count,
            difficulty,
            is_published,
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
