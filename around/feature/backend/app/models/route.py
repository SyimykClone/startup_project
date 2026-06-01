from datetime import datetime
from pydantic import BaseModel, Field
from typing import Dict, Any, Literal


Profile = Literal["walking", "driving", "cycling", "transit"]


class RouteRequest(BaseModel):
    from_lat: float = Field(..., description="Start latitude")
    from_lng: float = Field(..., description="Start longitude")
    to_lat: float = Field(..., description="Destination latitude")
    to_lng: float = Field(..., description="Destination longitude")
    profile: Profile = "walking"
    destination_name: str | None = None


class RouteResponse(BaseModel):
    distance_m: float
    duration_s: float
    geometry: Dict[str, Any] 


class RouteHistoryItem(BaseModel):
    id: int
    destination_name: str
    from_lat: float
    from_lng: float
    to_lat: float
    to_lng: float
    profile: Profile
    distance_m: float
    duration_s: float
    created_at: datetime
