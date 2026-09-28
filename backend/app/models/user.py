"""
User model.

IMPORTANT: This is meant to be the ONE user table for the whole project.
If Member 2 or Member 3 already created a `users` table, coordinate and use
theirs instead — do not let two separate user systems exist. The `role`
field below is designed to also cover buyer/seller-type roles so Marketplace
and Community can reuse this same table.
"""
import enum
import uuid

from sqlalchemy import Column, String, DateTime, Enum, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class UserRole(str, enum.Enum):
    FARMER = "farmer"
    BUYER = "buyer"          # reserved for Module 2 (Marketplace)
    ADMIN = "admin"
    COMMUNITY_MEMBER = "community_member"  # reserved for Module 3


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, index=True, nullable=False)
    phone = Column(String(20), unique=True, index=True, nullable=True)
    hashed_password = Column(String(255), nullable=False)
    role = Column(Enum(UserRole), nullable=False, default=UserRole.FARMER)
    is_active = Column(Boolean, default=True, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    farmer_profile = relationship(
        "FarmerProfile", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    farms = relationship("Farm", back_populates="owner", cascade="all, delete-orphan")
    feedback_entries = relationship(
        "FarmerFeedback", back_populates="farmer", cascade="all, delete-orphan"
    )


class FarmerProfile(Base):
    __tablename__ = "farmer_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), unique=True, nullable=False)

    full_name = Column(String(150), nullable=False)
    district = Column(String(100), nullable=True)
    location = Column(String(255), nullable=True)  # free-text or "lat,lng"
    profile_image_url = Column(String(500), nullable=True)
    farmer_info = Column(String(1000), nullable=True)  # bio / farming experience notes

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="farmer_profile")
