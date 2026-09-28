from fastapi import APIRouter, Depends

from app.core.dependencies import get_current_farmer
from app.models.user import User
from app.schemas.recommendation import (
    CropRecommendationRequest,
    CropRecommendationResponse,
    CropSuitabilityResponse,
)
from app.services.recommendation_service import RecommendationInput, recommend_crops

router = APIRouter(prefix="/crop-recommendations", tags=["crop-recommendations"])


@router.post("", response_model=CropRecommendationResponse)
def get_crop_recommendations(
    payload: CropRecommendationRequest,
    current_user: User = Depends(get_current_farmer),
):
    recommendation_input = RecommendationInput(
        soil_ph=payload.soil_ph,
        nitrogen=payload.nitrogen,
        phosphorus=payload.phosphorus,
        potassium=payload.potassium,
        temperature_c=payload.temperature_c,
        humidity_pct=payload.humidity_pct,
        rainfall_mm=payload.rainfall_mm,
        location=payload.location,
        season=payload.season,
        water_availability=payload.water_availability,
    )
    results = recommend_crops(recommendation_input)

    return CropRecommendationResponse(
        recommendations=[
            CropSuitabilityResponse(
                crop_name=r.crop_name,
                suitability_score=r.suitability_score,
                suitability_level=r.suitability_level,
                reasons=r.reasons,
                warnings=r.warnings,
            )
            for r in results
        ]
    )
