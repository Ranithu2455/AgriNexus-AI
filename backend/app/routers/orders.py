from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.models.user import User
from app.database import get_db
from app.models.order import Order, OrderStatus
from app.models.product import Listing, ListingStatus
from app.core.permissions import assert_is_order_buyer_or_seller, assert_is_order_seller
from app.schemas.order import OrderCreate, OrderDetailOut, OrderOut, OrderStatusUpdate

router = APIRouter(prefix="/api/orders", tags=["orders"])

# Status transitions a seller (or buyer, for cancellation) is allowed to make.
_ALLOWED_TRANSITIONS: dict[OrderStatus, set[OrderStatus]] = {
    OrderStatus.pending: {OrderStatus.accepted, OrderStatus.rejected, OrderStatus.cancelled},
    OrderStatus.accepted: {OrderStatus.completed, OrderStatus.cancelled},
    OrderStatus.rejected: set(),
    OrderStatus.completed: set(),
    OrderStatus.cancelled: set(),
}


@router.post("", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
def create_order(
    payload: OrderCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    listing = db.query(Listing).filter(Listing.id == payload.listing_id).first()
    if not listing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    if listing.status != ListingStatus.active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="This listing is not currently available")
    if listing.seller_id == current_user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You cannot order your own listing")
    if payload.quantity > listing.quantity:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Only {listing.quantity} {listing.unit} available",
        )

    order = Order(
        listing_id=listing.id,
        buyer_id=current_user.id,
        seller_id=listing.seller_id,
        quantity=payload.quantity,
        unit_price_snapshot=listing.price,
        total_price=listing.price * payload.quantity,
        message=payload.message,
        status=OrderStatus.pending,
    )
    db.add(order)
    db.commit()
    db.refresh(order)
    return order


@router.get("/my", response_model=list[OrderOut])
def my_orders_as_buyer(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(Order)
        .filter(Order.buyer_id == current_user.id)
        .order_by(Order.created_at.desc())
        .all()
    )


@router.get("/received", response_model=list[OrderOut])
def orders_received_as_seller(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(Order)
        .filter(Order.seller_id == current_user.id)
        .order_by(Order.created_at.desc())
        .all()
    )


@router.get("/{order_id}", response_model=OrderDetailOut)
def get_order(
    order_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    assert_is_order_buyer_or_seller(order, current_user)
    return order


@router.patch("/{order_id}/status", response_model=OrderOut)
def update_order_status(
    order_id: str,
    payload: OrderStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    # Buyers may only cancel their own pending order; everything else is seller-only.
    if payload.status == OrderStatus.cancelled and current_user.id == order.buyer_id:
        pass
    else:
        assert_is_order_seller(order, current_user)

    if payload.status not in _ALLOWED_TRANSITIONS.get(order.status, set()):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot move order from '{order.status.value}' to '{payload.status.value}'",
        )

    order.status = payload.status
    db.commit()
    db.refresh(order)
    return order
