from asyncpg.exceptions import CheckViolationError

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
    "app_started": "First launch",
    "profile_customized": "Profile tuned",
    "map_started": "Map opened",
    "favorite_started": "First saved place",
    "ar_object_found": "AR discovery",
    "custom_point_created": "Own place added",
    "all_rounder": "All-round explorer",
    "xp_100": "100 XP",
    "xp_500": "500 XP",
    "xp_750": "750 XP",
    "xp_1500": "1500 XP",
    "xp_2500": "2500 XP",
    "xp_3500": "3500 XP",
    "level_2": "Level 2",
    "level_3": "Level 3",
    "level_5": "Level 5",
    "level_7": "Level 7",
    "level_8": "Level 8",
    "level_10": "Level 10",
}

USER_ACHIEVEMENTS = {
    "profile_opened": "Traveler profile",
    "first_route": "First route built",
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
    "ten_favorites": "10 favorites",
    "first_custom_point": "First custom point",
    "three_custom_points": "3 custom points",
}

BUSINESS_ACHIEVEMENTS = {
    "business_profile_opened": "Business profile",
    "first_tour_created": "First tour draft",
    "three_tours_created": "3 tours created",
    "five_tours_created": "5 tours created",
    "first_draft_tour": "First draft tour",
    "first_tour_published": "First tour published",
    "three_tours_published": "3 tours published",
    "five_tours_published": "5 tours published",
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
    (100, "xp_100"),
    (500, "xp_500"),
    (750, "xp_750"),
    (1500, "xp_1500"),
    (2500, "xp_2500"),
    (3500, "xp_3500"),
]

LEVEL_ACHIEVEMENTS = [
    (2, "level_2"),
    (3, "level_3"),
    (5, "level_5"),
    (7, "level_7"),
    (8, "level_8"),
    (10, "level_10"),
]

FAVORITE_ACHIEVEMENTS = [
    (1, "first_favorite"),
    (5, "five_favorites"),
    (10, "ten_favorites"),
]

TOUR_ACHIEVEMENTS = [
    (1, "first_tour_created"),
    (3, "three_tours_created"),
    (5, "five_tours_created"),
]

CUSTOM_POINT_ACHIEVEMENTS = [
    (1, "first_custom_point"),
    (3, "three_custom_points"),
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
        SELECT $1
        WHERE NOT EXISTS (
          SELECT 1
          FROM users_gamification_progress
          WHERE users_id = $1
        )
        """,
        user_id,
    )


async def _unlock_achievement_if_needed(conn, user_id: int, code: str) -> None:
    try:
        async with conn.transaction():
            await conn.execute(
                """
                INSERT INTO users_achievements (users_id, code)
                SELECT $1, $2
                WHERE NOT EXISTS (
                  SELECT 1
                  FROM users_achievements
                  WHERE users_id = $1 AND code = $2
                )
                """,
                user_id,
                code,
            )
    except CheckViolationError:
        pass


async def _table_exists(conn, table_name: str) -> bool:
    exists = await conn.fetchval("SELECT to_regclass($1) IS NOT NULL", f"public.{table_name}")
    return bool(exists)


async def _column_exists(conn, table_name: str, column_name: str) -> bool:
    exists = await conn.fetchval(
        """
        SELECT EXISTS (
          SELECT 1
          FROM information_schema.columns
          WHERE table_schema = 'public'
            AND table_name = $1
            AND column_name = $2
        )
        """,
        table_name,
        column_name,
    )
    return bool(exists)


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
    username: str,
    avatar_path: str | None,
    xp: int,
    routes_built: int,
    new_places_visited: int,
    favorites_count: int,
    custom_points_count: int,
    ar_visits_count: int,
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
    await _unlock_achievement_if_needed(conn, user_id, "app_started")
    if avatar_path or (username and username.strip().lower() != "user"):
        await _unlock_achievement_if_needed(conn, user_id, "profile_customized")
    if routes_built >= 1:
        await _unlock_achievement_if_needed(conn, user_id, "map_started")
    if favorites_count >= 1:
        await _unlock_achievement_if_needed(conn, user_id, "favorite_started")
    if custom_points_count >= 1:
        await _unlock_achievement_if_needed(conn, user_id, "custom_point_created")
    if ar_visits_count >= 1:
        await _unlock_achievement_if_needed(conn, user_id, "ar_object_found")
    if (
        routes_built >= 1
        and new_places_visited >= 1
        and favorites_count >= 1
        and custom_points_count >= 1
    ):
        await _unlock_achievement_if_needed(conn, user_id, "all_rounder")
    if user_type == "business":
        for required_count, code in TOUR_ACHIEVEMENTS:
            if tours_created >= required_count:
                await _unlock_achievement_if_needed(conn, user_id, code)
        if tours_created > tours_published:
            await _unlock_achievement_if_needed(conn, user_id, "first_draft_tour")
        if tours_published >= 1:
            await _unlock_achievement_if_needed(conn, user_id, "first_tour_published")
        if tours_published >= 3:
            await _unlock_achievement_if_needed(conn, user_id, "three_tours_published")
        if tours_published >= 5:
            await _unlock_achievement_if_needed(conn, user_id, "five_tours_published")
        await _unlock_achievement_if_needed(conn, user_id, "business_profile_opened")
    else:
        for required_count, code in FAVORITE_ACHIEVEMENTS:
            if favorites_count >= required_count:
                await _unlock_achievement_if_needed(conn, user_id, code)
        for required_count, code in CUSTOM_POINT_ACHIEVEMENTS:
            if custom_points_count >= required_count:
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
            users_has_avatar = await _column_exists(conn, "users", "avatar_path")
            users_has_type = await _column_exists(conn, "users", "user_type")
            avatar_select = "avatar_path" if users_has_avatar else "NULL AS avatar_path"
            type_select = "user_type" if users_has_type else "'user' AS user_type"
            progress = await conn.fetchrow(
                """
                SELECT level, xp, routes_built, new_places_visited
                FROM users_gamification_progress
                WHERE users_id = $1
                """,
                user_id,
            )
            user_row = await conn.fetchrow(
                f"""
                SELECT username, {avatar_select}, {type_select}
                FROM users
                WHERE id = $1
                """,
                user_id,
            )
            username = str(user_row["username"] or "") if user_row else ""
            avatar_path = user_row["avatar_path"] if user_row else None
            user_type = str(user_row["user_type"] or "user") if user_row else "user"
            favorites_count = 0
            if await _table_exists(conn, "users_favorite_poi"):
                favorites_count = await conn.fetchval(
                    """
                    SELECT COUNT(*)
                    FROM users_favorite_poi
                    WHERE users_id = $1
                    """,
                    user_id,
                )

            custom_points_count = 0
            poi_exists = await _table_exists(conn, "poi")
            if poi_exists and await _column_exists(conn, "poi", "created_by_users_id"):
                custom_points_count = await conn.fetchval(
                    """
                    SELECT COUNT(*)
                    FROM poi
                    WHERE created_by_users_id = $1
                    """,
                    user_id,
                )

            ar_visits_count = 0
            if (
                poi_exists
                and await _table_exists(conn, "users_visited_poi")
                and await _column_exists(conn, "poi", "ar_enabled")
            ):
                ar_visits_count = await conn.fetchval(
                    """
                    SELECT COUNT(*)
                    FROM users_visited_poi vp
                    JOIN poi p ON p.id = vp.poi_id
                    WHERE vp.users_id = $1 AND p.ar_enabled = true
                    """,
                    user_id,
                )

            tours_created = 0
            tours_published = 0
            tours_exists = await _table_exists(conn, "tours")
            tours_has_owner = await _column_exists(conn, "tours", "business_user_id")
            if tours_exists and tours_has_owner:
                tours_created = await conn.fetchval(
                    """
                    SELECT COUNT(*)
                    FROM tours
                    WHERE business_user_id = $1
                    """,
                    user_id,
                )
                if await _column_exists(conn, "tours", "is_published"):
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
                user_type,
                username,
                avatar_path,
                int(progress["xp"]),
                int(progress["routes_built"]),
                int(progress["new_places_visited"]),
                int(favorites_count or 0),
                int(custom_points_count or 0),
                int(ar_visits_count or 0),
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
