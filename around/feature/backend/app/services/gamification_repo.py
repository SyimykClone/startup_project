from app.core.db import get_pool
from app.models.gamification import AchievementOut, GamificationMeOut

LEVEL_THRESHOLDS = [
    0,
    80,
    220,
    450,
    800,
    1250,
    1850,
    2600,
    3600,
    4800,
]
MAX_LEVEL = len(LEVEL_THRESHOLDS)
XP_ROUTE_BUILT = 8
XP_NEW_PLACE = 22

COMMON_ACHIEVEMENTS = {
    "xp_500": "500 XP",
    "xp_1500": "1500 XP",
    "xp_3500": "3500 XP",
    "level_3": "Level 3",
    "level_5": "Level 5",
    "level_8": "Level 8",
    "level_10": "Level 10",
}

USER_ACHIEVEMENTS = {
    "profile_opened": "Profile explored",
    "first_route": "First route",
    "five_routes": "5 routes",
    "ten_routes": "10 routes",
    "twenty_five_routes": "25 routes",
    "fifty_routes": "50 routes",
    "first_new_place": "First new place",
    "three_new_places": "3 new places",
    "ten_new_places": "10 new places",
    "twenty_five_new_places": "25 new places",
    "first_favorite": "First favorite",
    "five_favorites": "5 favorites",
}

BUSINESS_ACHIEVEMENTS = {
    "business_profile_opened": "Business profile explored",
    "first_tour_created": "First tour created",
    "three_tours_created": "3 tours created",
    "first_tour_published": "First tour published",
    "three_tours_published": "3 tours published",
}

ROUTE_ACHIEVEMENTS = [
    (1, "first_route"),
    (5, "five_routes"),
    (10, "ten_routes"),
    (25, "twenty_five_routes"),
    (50, "fifty_routes"),
]

PLACE_ACHIEVEMENTS = [
    (1, "first_new_place"),
    (3, "three_new_places"),
    (10, "ten_new_places"),
    (25, "twenty_five_new_places"),
]

XP_ACHIEVEMENTS = [
    (500, "xp_500"),
    (1500, "xp_1500"),
    (3500, "xp_3500"),
]

LEVEL_ACHIEVEMENTS = [
    (3, "level_3"),
    (5, "level_5"),
    (8, "level_8"),
    (10, "level_10"),
]

FAVORITE_ACHIEVEMENTS = [
    (1, "first_favorite"),
    (5, "five_favorites"),
]

TOUR_ACHIEVEMENTS = [
    (1, "first_tour_created"),
    (3, "three_tours_created"),
]


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
    for required_xp, code in XP_ACHIEVEMENTS:
        if xp >= required_xp:
            await _unlock_achievement_if_needed(conn, user_id, code)
    for required_level, code in LEVEL_ACHIEVEMENTS:
        if new_level >= required_level:
            await _unlock_achievement_if_needed(conn, user_id, code)


async def _sync_progress_rewards(
    conn,
    user_id: int,
    user_type: str,
    xp: int,
    routes_built: int,
    new_places_visited: int,
    favorites_count: int,
    tours_created: int,
    tours_published: int,
) -> int:
    level = _calculate_level(xp)
    await conn.execute(
        """
        UPDATE users_gamification_progress
        SET level = $2, updated_at = now()
        WHERE users_id = $1 AND level <> $2
        """,
        user_id,
        level,
    )
    for required_count, code in ROUTE_ACHIEVEMENTS:
        if routes_built >= required_count:
            await _unlock_achievement_if_needed(conn, user_id, code)
    for required_count, code in PLACE_ACHIEVEMENTS:
        if new_places_visited >= required_count:
            await _unlock_achievement_if_needed(conn, user_id, code)
    for required_xp, code in XP_ACHIEVEMENTS:
        if xp >= required_xp:
            await _unlock_achievement_if_needed(conn, user_id, code)
    for required_level, code in LEVEL_ACHIEVEMENTS:
        if level >= required_level:
            await _unlock_achievement_if_needed(conn, user_id, code)
    if user_type == "business":
        for required_count, code in TOUR_ACHIEVEMENTS:
            if tours_created >= required_count:
                await _unlock_achievement_if_needed(conn, user_id, code)
        if tours_published >= 1:
            await _unlock_achievement_if_needed(conn, user_id, "first_tour_published")
        if tours_published >= 3:
            await _unlock_achievement_if_needed(conn, user_id, "three_tours_published")
        await _unlock_achievement_if_needed(conn, user_id, "business_profile_opened")
    else:
        for required_count, code in FAVORITE_ACHIEVEMENTS:
            if favorites_count >= required_count:
                await _unlock_achievement_if_needed(conn, user_id, code)
        await _unlock_achievement_if_needed(conn, user_id, "profile_opened")
    return level


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
            for required_count, code in ROUTE_ACHIEVEMENTS:
                if routes_built >= required_count:
                    await _unlock_achievement_if_needed(conn, user_id, code)


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
            new_places_visited = await conn.fetchval(
                """
                SELECT new_places_visited
                FROM users_gamification_progress
                WHERE users_id = $1
                """,
                user_id,
            )
            for required_count, code in PLACE_ACHIEVEMENTS:
                if new_places_visited >= required_count:
                    await _unlock_achievement_if_needed(conn, user_id, code)


async def get_gamification_state(user_id: int) -> GamificationMeOut:
    pool = get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            await _ensure_progress(conn, user_id)
            progress = await conn.fetchrow(
                """
                SELECT level, xp, routes_built, new_places_visited
                FROM users_gamification_progress
                WHERE users_id = $1
                """,
                user_id,
            )
            user_type = await conn.fetchval(
                """
                SELECT user_type
                FROM users
                WHERE id = $1
                """,
                user_id,
            )
            favorites_count = await conn.fetchval(
                """
                SELECT COUNT(*)
                FROM users_favorite_poi
                WHERE users_id = $1
                """,
                user_id,
            )
            tours_created = await conn.fetchval(
                """
                SELECT COUNT(*)
                FROM tours
                WHERE business_user_id = $1
                """,
                user_id,
            )
            tours_published = await conn.fetchval(
                """
                SELECT COUNT(*)
                FROM tours
                WHERE business_user_id = $1 AND is_published = true
                """,
                user_id,
            )
            synced_level = await _sync_progress_rewards(
                conn,
                user_id,
                str(user_type or "user"),
                int(progress["xp"]),
                int(progress["routes_built"]),
                int(progress["new_places_visited"]),
                int(favorites_count or 0),
                int(tours_created or 0),
                int(tours_published or 0),
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
    level = synced_level

    current_threshold = LEVEL_THRESHOLDS[level - 1]
    next_threshold = LEVEL_THRESHOLDS[level] if level < MAX_LEVEL else None
    if next_threshold is None:
        progress_percent = 100.0
    else:
        span = max(1, next_threshold - current_threshold)
        progress_percent = min(100.0, max(0.0, (xp - current_threshold) * 100.0 / span))

    unlocked_codes = {r["code"] for r in unlocked_rows}
    visible_achievements = {
        **COMMON_ACHIEVEMENTS,
        **(
            BUSINESS_ACHIEVEMENTS
            if str(user_type or "user") == "business"
            else USER_ACHIEVEMENTS
        ),
    }
    achievements = [
        AchievementOut(code=code, title=title, unlocked=code in unlocked_codes)
        for code, title in visible_achievements.items()
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
