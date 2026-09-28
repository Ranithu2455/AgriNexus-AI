"""
Crop recommendation "AI" — implemented as a transparent rule-based scoring
engine over common Sri Lankan crops, NOT a black-box ML model. This is
intentional: it's explainable (every score comes with reasons), doesn't need
training data we don't have, and is honest about being decision support.

TO UPGRADE LATER: replace `score_crop()` internals with a trained model's
prediction while keeping the same `CropSuitability` output shape, so the
router/schema layer doesn't need to change.
"""
from dataclasses import dataclass, field


@dataclass
class CropProfile:
    """Ideal growing conditions for a crop, used as the scoring reference."""
    name: str
    ph_range: tuple[float, float]
    temp_range_c: tuple[float, float]
    rainfall_range_mm: tuple[float, float]  # monthly average
    water_need: str  # "low" | "moderate" | "high"
    preferred_seasons: list[str]


@dataclass
class RecommendationInput:
    soil_ph: float
    nitrogen: float
    phosphorus: float
    potassium: float
    temperature_c: float
    humidity_pct: float
    rainfall_mm: float
    location: str | None
    season: str | None
    water_availability: str  # "abundant" | "moderate" | "limited" | "none"


@dataclass
class CropSuitability:
    crop_name: str
    suitability_score: float  # 0-100
    suitability_level: str  # "high" | "moderate" | "low"
    reasons: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


# Reference profiles for common crops grown in Sri Lanka. Ranges are
# reasonable agronomic approximations for an MVP decision-support tool, not
# authoritative agricultural-extension data.
_CROP_PROFILES = [
    CropProfile("Rice (Paddy)", (5.5, 6.5), (20, 35), (150, 300), "high", ["Yala", "Maha"]),
    CropProfile("Tea", (4.5, 5.5), (15, 25), (150, 250), "moderate", ["Maha"]),
    CropProfile("Coconut", (5.0, 8.0), (25, 32), (100, 250), "moderate", ["Yala", "Maha"]),
    CropProfile("Chili", (5.5, 6.8), (20, 30), (60, 150), "moderate", ["Yala"]),
    CropProfile("Maize", (5.5, 7.0), (20, 30), (80, 180), "moderate", ["Yala", "Maha"]),
    CropProfile("Green Gram (Mung Bean)", (6.0, 7.5), (25, 35), (50, 120), "low", ["Yala"]),
    CropProfile("Tomato", (6.0, 6.8), (18, 28), (60, 130), "moderate", ["Yala", "Maha"]),
    CropProfile("Banana", (5.5, 7.0), (20, 30), (100, 220), "high", ["Yala", "Maha"]),
]

_WATER_LEVEL_RANK = {"none": 0, "limited": 1, "moderate": 2, "abundant": 3}
_NEED_LEVEL_RANK = {"low": 1, "moderate": 2, "high": 3}


def _score_range(value: float, low: float, high: float, tolerance_ratio: float = 0.25) -> float:
    """Return 0-100: 100 if inside [low, high], decaying linearly outside it."""
    if low <= value <= high:
        return 100.0
    span = max(high - low, 1e-6)
    tolerance = span * tolerance_ratio
    if value < low:
        distance = low - value
    else:
        distance = value - high
    if distance >= tolerance * 4:
        return 0.0
    return max(0.0, 100.0 - (distance / tolerance) * 25.0)


def score_crop(profile: CropProfile, data: RecommendationInput) -> CropSuitability:
    reasons: list[str] = []
    warnings: list[str] = []

    ph_score = _score_range(data.soil_ph, *profile.ph_range)
    temp_score = _score_range(data.temperature_c, *profile.temp_range_c)
    rain_score = _score_range(data.rainfall_mm, *profile.rainfall_range_mm)

    water_gap = _WATER_LEVEL_RANK[data.water_availability] - _NEED_LEVEL_RANK[profile.water_need]
    water_score = 100.0 if water_gap >= 0 else max(0.0, 100.0 + water_gap * 35.0)

    season_score = 100.0 if (data.season and data.season in profile.preferred_seasons) else 60.0

    overall = (
        ph_score * 0.25
        + temp_score * 0.2
        + rain_score * 0.2
        + water_score * 0.25
        + season_score * 0.10
    )

    if ph_score >= 80:
        reasons.append(f"Soil pH {data.soil_ph} is within {profile.name}'s ideal range {profile.ph_range}")
    elif ph_score < 50:
        warnings.append(f"Soil pH {data.soil_ph} is outside the ideal range {profile.ph_range} for {profile.name}")

    if temp_score >= 80:
        reasons.append(f"Temperature {data.temperature_c}°C suits {profile.name}")
    elif temp_score < 50:
        warnings.append(f"Temperature {data.temperature_c}°C is not ideal for {profile.name}")

    if rain_score >= 80:
        reasons.append(f"Rainfall of {data.rainfall_mm}mm matches {profile.name}'s needs")
    elif rain_score < 50:
        warnings.append(f"Rainfall of {data.rainfall_mm}mm may be insufficient or excessive for {profile.name}")

    if water_gap < 0:
        warnings.append(f"{profile.name} typically needs {profile.water_need} water availability")
    else:
        reasons.append(f"Water availability ({data.water_availability}) meets {profile.name}'s needs")

    if data.season and data.season not in profile.preferred_seasons:
        warnings.append(f"{data.season} is not the typical growing season for {profile.name}")

    if data.nitrogen < 20:
        warnings.append("Nitrogen level is low — consider soil amendment before planting")
    if data.phosphorus < 15:
        warnings.append("Phosphorus level is low — may affect root development")
    if data.potassium < 15:
        warnings.append("Potassium level is low — may affect fruit/grain quality")

    level = "high" if overall >= 75 else "moderate" if overall >= 50 else "low"

    return CropSuitability(
        crop_name=profile.name,
        suitability_score=round(overall, 1),
        suitability_level=level,
        reasons=reasons,
        warnings=warnings,
    )


def recommend_crops(data: RecommendationInput, top_n: int = 5) -> list[CropSuitability]:
    results = [score_crop(profile, data) for profile in _CROP_PROFILES]
    results.sort(key=lambda r: r.suitability_score, reverse=True)
    return results[:top_n]
