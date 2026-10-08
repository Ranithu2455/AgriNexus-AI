from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.user import User, UserRole
from app.database import get_db
from app.models.order import Review
from app.models.product import Listing, ListingStatus, ListingType
from app.schemas.product import ListingOut
from app.schemas.supplier import SellerSummary

router = APIRouter(prefix="/api/suppliers", tags=["suppliers"])


@router.get("/{user_id}", response_model=SellerSummary)
def get_supplier_profile(user_id: str, db: Session = Depends(get_db)):
    supplier = db.query(User).filter(User.id == user_id, User.role == UserRole.supplier).first()
    if not supplier:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Supplier not found")
    return supplier


@router.get("/{user_id}/products", response_model=list[ListingOut])
def get_supplier_products(
    user_id: str,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    return (
        db.query(Listing)
        .filter(
            Listing.seller_id == user_id,
            Listing.listing_type == ListingType.supplier_product,
            Listing.status == ListingStatus.active,
        )
        .order_by(Listing.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )


@router.get("/{user_id}/rating")
def get_supplier_rating(user_id: str, db: Session = Depends(get_db)):
    row = db.query(func.avg(Review.rating), func.count(Review.id)).filter(Review.reviewee_id == user_id).first()
    return {
        "average_rating": float(row[0]) if row and row[0] is not None else None,
        "review_count": int(row[1]) if row else 0,
    }
