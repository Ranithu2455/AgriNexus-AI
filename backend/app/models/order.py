import enum
import uuid

from sqlalchemy import (
    Column, String, Text, Integer, Numeric, Boolean, DateTime,
    ForeignKey, Enum, UniqueConstraint, Index,
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


def _uuid() -> str:
    return str(uuid.uuid4())


class OrderStatus(str, enum.Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"
    completed = "completed"
    cancelled = "cancelled"


class Order(Base):
    """A buyer's request/order against a listing. MVP flow — no payment integration."""

    __tablename__ = "orders"

    id = Column(String(36), primary_key=True, default=_uuid)
    listing_id = Column(String(36), ForeignKey("listings.id"), nullable=False, index=True)
    buyer_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    seller_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)

    quantity = Column(Numeric(12, 2), nullable=False)
    unit_price_snapshot = Column(Numeric(12, 2), nullable=False)
    total_price = Column(Numeric(12, 2), nullable=False)
    message = Column(Text, nullable=True)
    status = Column(Enum(OrderStatus), nullable=False, default=OrderStatus.pending, index=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    listing = relationship("Listing", back_populates="orders")
    review = relationship("Review", back_populates="order", uselist=False, cascade="all, delete-orphan")


class Review(Base):
    """One review per completed order, left by the buyer about the seller."""

    __tablename__ = "reviews"

    id = Column(String(36), primary_key=True, default=_uuid)
    order_id = Column(String(36), ForeignKey("orders.id"), nullable=False, unique=True)
    reviewer_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    reviewee_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    rating = Column(Integer, nullable=False)  # 1-5, enforced in schema + CHECK constraint
    comment = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    order = relationship("Order", back_populates="review")

    __table_args__ = (
        UniqueConstraint("order_id", name="uq_review_per_order"),
    )
