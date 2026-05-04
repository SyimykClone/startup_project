from pydantic import BaseModel, Field


class Tour(BaseModel):
    id: int
    business_user_id: int
    title: str
    description: str
    duration_days: int
    price: float
    distance_km: float
    stops_count: int
    difficulty: str
    is_published: bool


class TourCreateIn(BaseModel):
    title: str = Field(min_length=3, max_length=120)
    description: str = Field(min_length=3, max_length=2000)
    duration_days: int = Field(ge=1, le=60)
    price: float = Field(ge=0, le=1_000_000)
    distance_km: float = Field(gt=0, le=5000)
    stops_count: int = Field(default=1, ge=1, le=200)
    difficulty: str = Field(default="easy", pattern="^(easy|medium|hard)$")
    is_published: bool = False


class TourUpdateIn(BaseModel):
    title: str | None = Field(default=None, min_length=3, max_length=120)
    description: str | None = Field(default=None, min_length=3, max_length=2000)
    duration_days: int | None = Field(default=None, ge=1, le=60)
    price: float | None = Field(default=None, ge=0, le=1_000_000)
    distance_km: float | None = Field(default=None, gt=0, le=5000)
    stops_count: int | None = Field(default=None, ge=1, le=200)
    difficulty: str | None = Field(default=None, pattern="^(easy|medium|hard)$")
    is_published: bool | None = None
