import enum
import uuid

from sqlalchemy import Column, String, DateTime, Enum, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class WaterAvailability(str, enum.Enum):
    ABUNDANT = "abundant"
    MODERATE = "moderate"
    LIMITED = "limited"
    NONE = "none"


class Farm(Base):
    __tablename__ = "farms"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    owner_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)

    name = Column(String(150), nullable=False)
    location = Column(String(255), nullable=True)
    district = Column(String(100), nullable=True)
    size_acres = Column(Float, nullable=True)
    soil_info = Column(String(500), nullable=True)  # e.g. soil type, pH notes
    water_availability = Column(Enum(WaterAvailability), default=WaterAvailability.MODERATE)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    owner = relationship("User", back_populates="farms")
    crops = relationship("Crop", back_populates="farm", cascade="all, delete-orphan")
