from pydantic import BaseModel


class WeatherResponse(BaseModel):
    location: str
    temperature_c: float
    humidity_pct: float
    condition: str
    description: str
    rainfall_mm_last_hour: float
    wind_speed_ms: float
    is_mock_result: bool
    advisories: list[str]
