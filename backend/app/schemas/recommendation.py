from typing import Optional, Literal

from pydantic import BaseModel, Field


class CropRecommendationRequest(BaseModel):
    soil_ph: float = Field(..., ge=0, le=14)
    nitrogen: float = Field(..., ge=0, description="mg/kg or index value")
    phosphorus: float = Field(..., ge=0)
    potassium: float = Field(..., ge=0)
    temperature_c: float
    humidity_pct: float = Field(..., ge=0, le=100)
    rainfall_mm: float = Field(..., ge=0, description="Average monthly rainfall")
    location: Optional[str] = None
    season: Optional[Literal["Yala", "Maha"]] = None
    water_availability: Literal["abundant", "moderate", "limited", "none"] = "moderate"


class CropSuitabilityResponse(BaseModel):
    crop_name: str
    suitability_score: float
    suitability_level: str
    reasons: list[str]
    warnings: list[str]


class CropRecommendationResponse(BaseModel):
    recommendations: list[CropSuitabilityResponse]
    disclaimer: str = (
        "These recommendations are decision support based on general agronomic "
        "guidelines, not guaranteed agricultural advice. Confirm with a local "
        "agricultural officer before making planting decisions."
    )
