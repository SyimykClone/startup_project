from pydantic import BaseModel, Field
from typing import Dict, Any, Literal


Profile = Literal["walking", "driving", "cycling"]


class RouteRequest(BaseModel):
    from_lat: float = Field(..., description="Start latitude")
    from_lng: float = Field(..., description="Start longitude")
    to_lat: float = Field(..., description="Destination latitude")
    to_lng: float = Field(..., description="Destination longitude")
    profile: Profile = "walking"


class RouteResponse(BaseModel):
    distance_m: float
    duration_s: float
    geometry: Dict[str, Any] 
