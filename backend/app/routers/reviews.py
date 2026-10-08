from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.models.user import User
from app.database import get_db
from app.models.order import Order, OrderStatus, Review
from app.schemas.order import ReviewCreate, ReviewOut

router = APIRouter(prefix="/api/reviews", tags=["reviews"])


@router.post("", response_model=ReviewOut, status_code=status.HTTP_201_CREATED)
def create_review(
    payload: ReviewCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = db.query(Order).filter(Order.id == payload.order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if order.buyer_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only the buyer can review this order")
    if order.status != OrderStatus.completed:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only completed orders can be reviewed")
    if db.query(Review).filter(Review.order_id == order.id).first():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="This order has already been reviewed")

    review = Review(
        order_id=order.id,
        reviewer_id=current_user.id,
        reviewee_id=order.seller_id,
        rating=payload.rating,
        comment=payload.comment,
    )
    db.add(review)
    db.commit()
    db.refresh(review)
    return review


@router.get("/user/{user_id}", response_model=list[ReviewOut])
def reviews_for_user(user_id: str, db: Session = Depends(get_db)):
    return (
        db.query(Review)
        .filter(Review.reviewee_id == user_id)
        .order_by(Review.created_at.desc())
        .all()
    )


@router.get("/order/{order_id}", response_model=ReviewOut)
def review_for_order(order_id: str, db: Session = Depends(get_db)):
    review = db.query(Review).filter(Review.order_id == order_id).first()
    if not review:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No review for this order")
    return review
