from app.core.db import get_pool
from app.models.gamification import AchievementOut, GamificationMeOut

LEVEL_THRESHOLDS = [0, 100, 250, 450, 700]
MAX_LEVEL = 5
XP_ROUTE_BUILT = 10
XP_NEW_PLACE = 30

ACHIEVEMENTS = {
    "first_route": "First route",
    "five_routes": "5 routes",
    "first_new_place": "First new place",
}


def _calculate_level(xp: int) -> int:
    level = 1
    for idx, threshold in enumerate(LEVEL_THRESHOLDS, start=1):
        if xp >= threshold:
            level = idx
    return min(level, MAX_LEVEL)


async def _ensure_progress(conn, user_id: int) -> None:
    await conn.execute(
        """
        INSERT INTO users_gamification_progress (users_id)
        VALUES ($1)
        ON CONFLICT (users_id) DO NOTHING
        """,
        user_id,
    )


async def _unlock_achievement_if_needed(conn, user_id: int, code: str) -> None:
    await conn.execute(
        """
        INSERT INTO users_achievements (users_id, code)
        VALUES ($1, $2)
        ON CONFLICT (users_id, code) DO NOTHING
        """,
        user_id,
        code,
    )


async def _add_xp_and_recalc_level(conn, user_id: int, delta_xp: int) -> None:
    row = await conn.fetchrow(
        """
        UPDATE users_gamification_progress
        SET
          xp = xp + $2,
          level = 1,
          updated_at = now()
        WHERE users_id = $1
        RETURNING xp
        """,
        user_id,
        delta_xp,
    )
    xp = int(row["xp"])
    new_level = _calculate_level(xp)
    await conn.execute(
        """
        UPDATE users_gamification_progress
        SET level = $2, updated_at = now()
        WHERE users_id = $1
        """,
        user_id,
        new_level,
    )


async def register_route_built(user_id: int) -> None:
    pool = get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            await _ensure_progress(conn, user_id)
            await conn.execute(
                """
                UPDATE users_gamification_progress
                SET routes_built = routes_built + 1, updated_at = now()
                WHERE users_id = $1
                """,
                user_id,
            )
            await _add_xp_and_recalc_level(conn, user_id, XP_ROUTE_BUILT)

            routes_built = await conn.fetchval(
                """
                SELECT routes_built
                FROM users_gamification_progress
                WHERE users_id = $1
                """,
                user_id,
            )
            if routes_built >= 1:
                await _unlock_achievement_if_needed(conn, user_id, "first_route")
            if routes_built >= 5:
                await _unlock_achievement_if_needed(conn, user_id, "five_routes")


async def register_new_place_visit(user_id: int) -> None:
    pool = get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            await _ensure_progress(conn, user_id)
            await conn.execute(
                """
                UPDATE users_gamification_progress
                SET new_places_visited = new_places_visited + 1, updated_at = now()
                WHERE users_id = $1
                """,
                user_id,
            )
            await _add_xp_and_recalc_level(conn, user_id, XP_NEW_PLACE)
            await _unlock_achievement_if_needed(conn, user_id, "first_new_place")


async def get_gamification_state(user_id: int) -> GamificationMeOut:
    pool = get_pool()
    async with pool.acquire() as conn:
        await _ensure_progress(conn, user_id)
        progress = await conn.fetchrow(
            """
            SELECT level, xp, routes_built, new_places_visited
            FROM users_gamification_progress
            WHERE users_id = $1
            """,
            user_id,
        )
        unlocked_rows = await conn.fetch(
            """
            SELECT code
            FROM users_achievements
            WHERE users_id = $1
            """,
            user_id,
        )

    xp = int(progress["xp"])
    level = int(progress["level"])

    current_threshold = LEVEL_THRESHOLDS[level - 1]
    next_threshold = LEVEL_THRESHOLDS[level] if level < MAX_LEVEL else None
    if next_threshold is None:
        progress_percent = 100.0
    else:
        span = max(1, next_threshold - current_threshold)
        progress_percent = min(100.0, max(0.0, (xp - current_threshold) * 100.0 / span))

    unlocked_codes = {r["code"] for r in unlocked_rows}
    achievements = [
        AchievementOut(code=code, title=title, unlocked=code in unlocked_codes)
        for code, title in ACHIEVEMENTS.items()
    ]

    return GamificationMeOut(
        level=level,
        xp=xp,
        current_level_xp=current_threshold,
        next_level_xp=next_threshold,
        xp_progress_percent=round(progress_percent, 1),
        routes_built=int(progress["routes_built"]),
        new_places_visited=int(progress["new_places_visited"]),
        achievements=achievements,
    )
