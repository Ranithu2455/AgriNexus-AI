from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_farmer
from app.database import get_db
from app.models.crop import Crop
from app.models.farm import Farm
from app.models.feedback import FarmerFeedback
from app.models.user import User
from app.schemas.feedback import FarmerFeedbackCreate, FarmerFeedbackResponse

router = APIRouter(prefix="/farmer-feedback", tags=["farmer-feedback"])


@router.post("", response_model=FarmerFeedbackResponse, status_code=201)
def create_feedback(
    payload: FarmerFeedbackCreate,
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    if payload.farm_id:
        farm = db.query(Farm).filter(Farm.id == payload.farm_id).first()
        if not farm or farm.owner_id != current_user.id:
            raise HTTPException(status_code=403, detail="You do not own this farm")

    if payload.crop_id:
        crop = db.query(Crop).join(Farm).filter(Crop.id == payload.crop_id).first()
        if not crop or crop.farm.owner_id != current_user.id:
            raise HTTPException(status_code=403, detail="You do not own this crop")

    feedback = FarmerFeedback(
        farmer_id=current_user.id,
        feedback_type=payload.feedback_type,
        description=payload.description,
        farm_id=payload.farm_id,
        crop_id=payload.crop_id,
    )
    db.add(feedback)
    db.commit()
    db.refresh(feedback)
    return feedback


@router.get("", response_model=list[FarmerFeedbackResponse])
def list_my_feedback(
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    return (
        db.query(FarmerFeedback)
        .filter(FarmerFeedback.farmer_id == current_user.id)
        .order_by(FarmerFeedback.created_at.desc())
        .all()
    )
