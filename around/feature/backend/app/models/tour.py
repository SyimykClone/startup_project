from pydantic import BaseModel, Field


class Tour(BaseModel):
    id: int
    business_user_id: int
    title: str
    description: str
    duration_min: int
    distance_km: float


class TourCreateIn(BaseModel):
    title: str = Field(min_length=3, max_length=120)
    description: str = Field(min_length=3, max_length=2000)
    duration_min: int = Field(ge=1, le=24 * 60)
    distance_km: float = Field(gt=0, le=5000)


class TourUpdateIn(BaseModel):
    title: str | None = Field(default=None, min_length=3, max_length=120)
    description: str | None = Field(default=None, min_length=3, max_length=2000)
    duration_min: int | None = Field(default=None, ge=1, le=24 * 60)
    distance_km: float | None = Field(default=None, gt=0, le=5000)
