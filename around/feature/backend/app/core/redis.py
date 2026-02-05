import redis.asyncio as redis
from app.core.config import settings

_redis: redis.Redis | None = None

async def connect_redis() -> None:
    global _redis
    if _redis is not None:
        return
    _redis = redis.from_url(settings.REDIS_URL, decode_responses=True)

async def close_redis() -> None:
    global _redis
    if _redis is None:
        return
    await _redis.close()
    _redis = None

def get_redis() -> redis.Redis:
    if _redis is None:
        raise RuntimeError("Redis is not connected")
    return _redis
