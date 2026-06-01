from pydantic import BaseModel


class AchievementOut(BaseModel):
    code: str
    title: str
    unlocked: bool


class GamificationMeOut(BaseModel):
    level: int
    xp: int
    current_level_xp: int
    next_level_xp: int | None = None
    xp_progress_percent: float
    routes_built: int
    new_places_visited: int
    achievements: list[AchievementOut]
