from fastapi import APIRouter, Depends, Query

from app.core.dependencies import get_current_farmer
from app.models.user import User
from app.schemas.weather import WeatherResponse
from app.services.weather_service import fetch_current_weather, generate_agri_advice

router = APIRouter(prefix="/weather", tags=["weather"])


@router.get("", response_model=WeatherResponse)
async def get_weather(
    location: str = Query(..., description="District or town name, e.g. 'Kurunegala'"),
    lat: float | None = Query(None),
    lon: float | None = Query(None),
    current_user: User = Depends(get_current_farmer),
):
    weather = await fetch_current_weather(location, lat, lon)
    advisories = generate_agri_advice(weather)

    return WeatherResponse(
        location=weather.location,
        temperature_c=weather.temperature_c,
        humidity_pct=weather.humidity_pct,
        condition=weather.condition,
        description=weather.description,
        rainfall_mm_last_hour=weather.rainfall_mm_last_hour,
        wind_speed_ms=weather.wind_speed_ms,
        is_mock_result=weather.is_mock_result,
        advisories=advisories,
    )
