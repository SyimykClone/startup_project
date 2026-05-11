from pydantic import BaseModel
from typing import Optional


class Poi(BaseModel):
    id: int
    name: str
    description: str
    latitude: float
    longitude: float
    category: Optional[str] = None
    ar_enabled: bool = False
    ar_model_asset: Optional[str] = None
    ar_title: Optional[str] = None
    ar_description: Optional[str] = None
    ar_radius_m: int = 120


class CustomPoiFromCoordinatesIn(BaseModel):
    lat: float
    lng: float
    language: str = "ru"
