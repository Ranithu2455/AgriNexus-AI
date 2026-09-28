"""
Weather lookup + rule-based agricultural advice.

Uses OpenWeatherMap by default (set WEATHER_API_KEY in .env). If no API key
is configured, falls back to a clearly-labeled mock response so the endpoint
still works during development without external dependencies.
"""
from dataclasses import dataclass, field

import httpx

from app.config import settings


@dataclass
class WeatherSnapshot:
    location: str
    temperature_c: float
    humidity_pct: float
    condition: str          # e.g. "Rain", "Clear", "Clouds"
    description: str        # e.g. "moderate rain"
    rainfall_mm_last_hour: float
    wind_speed_ms: float
    is_mock_result: bool = False


@dataclass
class WeatherAdvice:
    weather: WeatherSnapshot
    advisories: list[str] = field(default_factory=list)


def _mock_weather(location: str) -> WeatherSnapshot:
    return WeatherSnapshot(
        location=location,
        temperature_c=29.0,
        humidity_pct=80.0,
        condition="Rain",
        description="moderate rain",
        rainfall_mm_last_hour=4.5,
        wind_speed_ms=3.2,
        is_mock_result=True,
    )


async def fetch_current_weather(location: str, lat: float | None = None, lon: float | None = None) -> WeatherSnapshot:
    if not settings.weather_api_key:
        return _mock_weather(location)

    params = {"appid": settings.weather_api_key, "units": "metric"}
    if lat is not None and lon is not None:
        params.update({"lat": lat, "lon": lon})
    else:
        params["q"] = f"{location},LK"

    url = f"{settings.weather_api_base_url}/weather"
    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            resp = await client.get(url, params=params)
            resp.raise_for_status()
            data = resp.json()
        except (httpx.HTTPError, ValueError):
            # External API unavailable — degrade gracefully instead of 500ing
            fallback = _mock_weather(location)
            fallback.is_mock_result = True
            return fallback

    weather_main = data.get("weather", [{}])[0]
    return WeatherSnapshot(
        location=location,
        temperature_c=data.get("main", {}).get("temp", 0.0),
        humidity_pct=data.get("main", {}).get("humidity", 0.0),
        condition=weather_main.get("main", "Unknown"),
        description=weather_main.get("description", ""),
        rainfall_mm_last_hour=data.get("rain", {}).get("1h", 0.0),
        wind_speed_ms=data.get("wind", {}).get("speed", 0.0),
        is_mock_result=False,
    )


def generate_agri_advice(weather: WeatherSnapshot) -> list[str]:
    advisories: list[str] = []

    if weather.condition.lower() in ("rain", "thunderstorm") or weather.rainfall_mm_last_hour > 2:
        advisories.append("Heavy rain expected or occurring — check field drainage to prevent waterlogging")
        advisories.append("Consider delaying fertilizer application until rain subsides")
        advisories.append("Monitor for fungal disease risk due to prolonged leaf wetness")

    if weather.humidity_pct >= 85:
        advisories.append("High humidity increases fungal and bacterial disease risk — inspect crops closely")

    if weather.temperature_c >= 34:
        advisories.append("High temperature — ensure adequate irrigation to prevent heat stress")

    if weather.condition.lower() == "clear" and weather.humidity_pct < 40:
        advisories.append("Dry conditions — monitor soil moisture and consider irrigation")

    if weather.wind_speed_ms >= 10:
        advisories.append("Strong winds expected — secure young plants and check for structural damage risk")

    if not advisories:
        advisories.append("Conditions look favorable — continue routine monitoring")

    return advisories
