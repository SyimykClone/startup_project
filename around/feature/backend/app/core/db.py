import asyncpg
from asyncpg.pool import Pool
from app.core.config import settings

_pool: Pool | None = None


async def connect_db() -> None:
    global _pool
    if _pool is not None:
        return

    _pool = await asyncpg.create_pool(
        dsn=settings.DATABASE_URL,
        min_size=1,
        max_size=5,
        command_timeout=10,
        # Supabase transaction pooler (pgbouncer) is incompatible with
        # asyncpg prepared statement cache.
        statement_cache_size=0,
    )


async def close_db() -> None:
    global _pool
    if _pool is None:
        return
    await _pool.close()
    _pool = None


def get_pool() -> Pool:
    if _pool is None:
        raise RuntimeError("Database is not connected (pool is None)")
    return _pool
