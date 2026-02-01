from pydantic import BaseModel
from typing import Optional


class Poi(BaseModel):
    id: int
    name: str
    description: str
    latitude: float
    longitude: float
    category: Optional[str] = None
