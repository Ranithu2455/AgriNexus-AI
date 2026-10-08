"""
Marketplace domain models.

Ownership note: `Listing.seller_id`, `Order.buyer_id`, `Review.reviewer_id`
etc. all reference `authentication.models.User.id` — the ONE shared users
table. There is no separate marketplace-only user record.
"""
import enum
import uuid

from sqlalchemy import (
    Column, String, Text, Integer, Numeric, Boolean, DateTime,
    ForeignKey, Enum, UniqueConstraint, Index,
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base
from app.models.supplier import SupplierProductType


def _uuid() -> str:
    return str(uuid.uuid4())


class ListingType(str, enum.Enum):
    farmer_product = "farmer_product"
    supplier_product = "supplier_product"


class ListingStatus(str, enum.Enum):
    active = "active"
    inactive = "inactive"
    sold_out = "sold_out"


class Category(Base):
    __tablename__ = "categories"

    id = Column(String(36), primary_key=True, default=_uuid)
    name = Column(String(150), nullable=False)
    slug = Column(String(160), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    parent_id = Column(String(36), ForeignKey("categories.id"), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    children = relationship("Category", backref="parent", remote_side=[id])
    listings = relationship("Listing", back_populates="category")


class Listing(Base):
    __tablename__ = "listings"

    id = Column(String(36), primary_key=True, default=_uuid)
    seller_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    category_id = Column(String(36), ForeignKey("categories.id"), nullable=False, index=True)

    listing_type = Column(Enum(ListingType), nullable=False, default=ListingType.farmer_product)
    supplier_product_type = Column(Enum(SupplierProductType), nullable=True)

    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    quantity = Column(Numeric(12, 2), nullable=False)
    unit = Column(String(30), nullable=False)  # kg, bag, liter, unit, etc.
    price = Column(Numeric(12, 2), nullable=False)
    currency = Column(String(10), nullable=False, default="LKR")
    location = Column(String(255), nullable=True)
    available_date = Column(DateTime(timezone=True), nullable=True)
    status = Column(Enum(ListingStatus), nullable=False, default=ListingStatus.active, index=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    category = relationship("Category", back_populates="listings")
    images = relationship("ListingImage", back_populates="listing", cascade="all, delete-orphan")
    orders = relationship("Order", back_populates="listing")
    inquiries = relationship("Inquiry", back_populates="listing", cascade="all, delete-orphan")

    __table_args__ = (
        Index("ix_listings_type_status", "listing_type", "status"),
    )


class ListingImage(Base):
    __tablename__ = "listing_images"

    id = Column(String(36), primary_key=True, default=_uuid)
    listing_id = Column(String(36), ForeignKey("listings.id"), nullable=False, index=True)
    image_url = Column(String(500), nullable=False)
    is_primary = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    listing = relationship("Listing", back_populates="images")


class Inquiry(Base):
    __tablename__ = "inquiries"

    id = Column(String(36), primary_key=True, default=_uuid)
    listing_id = Column(String(36), ForeignKey("listings.id"), nullable=False, index=True)
    buyer_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    message = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    listing = relationship("Listing", back_populates="inquiries")
