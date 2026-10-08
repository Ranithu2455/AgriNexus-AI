from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.models.user import User
from app.database import get_db
from app.models.product import Inquiry
from app.schemas.product import InquiryOut
from app.schemas.supplier import SellerSummary

router = APIRouter(prefix="/api/buyers", tags=["buyers"])


@router.get("/{user_id}", response_model=SellerSummary)
def get_buyer_profile(user_id: str, db: Session = Depends(get_db)):
    buyer = db.query(User).filter(User.id == user_id).first()
    if not buyer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Buyer not found")
    return buyer


@router.get("/me/inquiries", response_model=list[InquiryOut])
def my_sent_inquiries(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(Inquiry)
        .filter(Inquiry.buyer_id == current_user.id)
        .order_by(Inquiry.created_at.desc())
        .all()
    )
