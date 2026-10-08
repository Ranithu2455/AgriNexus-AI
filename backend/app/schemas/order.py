from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field, field_validator

from app.models.order import OrderStatus
from app.schemas.product import ListingOut
from app.schemas.supplier import SellerSummary


class OrderCreate(BaseModel):
    listing_id: str
    quantity: Decimal = Field(gt=0)
    message: str | None = None


class OrderStatusUpdate(BaseModel):
    status: OrderStatus


class OrderOut(BaseModel):
    id: str
    listing_id: str
    buyer_id: str
    seller_id: str
    quantity: Decimal
    unit_price_snapshot: Decimal
    total_price: Decimal
    message: str | None
    status: OrderStatus
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class OrderDetailOut(OrderOut):
    listing: ListingOut
    buyer: SellerSummary
    seller: SellerSummary


class ReviewCreate(BaseModel):
    order_id: str
    rating: int = Field(ge=1, le=5)
    comment: str | None = Field(default=None, max_length=2000)


class ReviewOut(BaseModel):
    id: str
    order_id: str
    reviewer_id: str
    reviewee_id: str
    rating: int
    comment: str | None
    created_at: datetime

    class Config:
        from_attributes = True
