from typing import List, Optional
from app.models.poi import Poi

_POI: List[Poi] = [
    Poi(
        id=1,
        name="Манап бий",
        description="Памятник Манап бию",
        latitude=42.828912,
        longitude=75.289289,
        category="monument",
    ),
    Poi(
        id=2,
        name="Султан Ибраимов",
        description="Памятник Султану Ибраимову",
        latitude=42.837473,
        longitude=75.295916,
        category="monument",
    ),
    Poi(
        id=3,
        name="Памятник героям ВОВ",
        description="Памятник героям Великой Отечественной войны",
        latitude=42.838049,
        longitude=75.295218,
        category="memorial",
    ),
]


def list_poi() -> List[Poi]:
    return _POI


def get_poi(poi_id: int) -> Optional[Poi]:
    for p in _POI:
        if p.id == poi_id:
            return p
    return None
