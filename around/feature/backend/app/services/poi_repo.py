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
