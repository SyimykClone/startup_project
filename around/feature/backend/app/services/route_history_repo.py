from typing import List

from app.core.db import get_pool
from app.models.route import RouteHistoryItem, RouteRequest, RouteResponse


async def ensure_route_history_table() -> None:
    pool = get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            """
            CREATE TABLE IF NOT EXISTS users_route_history (
                id SERIAL PRIMARY KEY,
                users_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                destination_name TEXT NOT NULL,
                from_lat DOUBLE PRECISION NOT NULL,
                from_lng DOUBLE PRECISION NOT NULL,
                to_lat DOUBLE PRECISION NOT NULL,
                to_lng DOUBLE PRECISION NOT NULL,
                profile TEXT NOT NULL,
                distance_m DOUBLE PRECISION NOT NULL,
                duration_s DOUBLE PRECISION NOT NULL,
                created_at TIMESTAMPTZ NOT NULL DEFAULT now()
            )
            """
        )
        await conn.execute(
            """
            CREATE INDEX IF NOT EXISTS idx_users_route_history_user_created
            ON users_route_history(users_id, created_at DESC)
            """
        )


async def save_route_history(
    users_id: int,
    req: RouteRequest,
    route: RouteResponse,
) -> None:
    await ensure_route_history_table()
    destination_name = req.destination_name or "Selected destination"
    pool = get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            """
            INSERT INTO users_route_history (
                users_id, destination_name, from_lat, from_lng,
                to_lat, to_lng, profile, distance_m, duration_s
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            """,
            users_id,
            destination_name,
            req.from_lat,
            req.from_lng,
            req.to_lat,
            req.to_lng,
            req.profile,
            route.distance_m,
            route.duration_s,
        )


async def list_route_history(users_id: int, limit: int = 10) -> List[RouteHistoryItem]:
    await ensure_route_history_table()
    pool = get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT id, destination_name, from_lat, from_lng, to_lat, to_lng,
                   profile, distance_m, duration_s, created_at
            FROM users_route_history
            WHERE users_id = $1
            ORDER BY created_at DESC
            LIMIT $2
            """,
            users_id,
            limit,
        )

    return [
        RouteHistoryItem(
            id=row["id"],
            destination_name=row["destination_name"],
            from_lat=row["from_lat"],
            from_lng=row["from_lng"],
            to_lat=row["to_lat"],
            to_lng=row["to_lng"],
            profile=row["profile"],
            distance_m=row["distance_m"],
            duration_s=row["duration_s"],
            created_at=row["created_at"],
        )
        for row in rows
    ]
