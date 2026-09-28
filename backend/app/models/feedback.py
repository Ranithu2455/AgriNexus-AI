import enum
import uuid

from sqlalchemy import Column, String, DateTime, Enum, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class FeedbackType(str, enum.Enum):
    WATERLOGGING = "waterlogging"
    DROUGHT = "drought"
    SALINITY = "salinity"
    PEST_OUTBREAK = "pest_outbreak"
    DISEASE_OUTBREAK = "disease_outbreak"
    UNEXPECTED_WEATHER = "unexpected_weather"
    CROP_GROWTH_PROBLEM = "crop_growth_problem"
    OTHER = "other"


class FarmerFeedback(Base):
    __tablename__ = "farmer_feedback"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farmer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farms.id"), nullable=True, index=True)
    crop_id = Column(UUID(as_uuid=True), ForeignKey("crops.id"), nullable=True, index=True)

    feedback_type = Column(Enum(FeedbackType), nullable=False)
    description = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    farmer = relationship("User", back_populates="feedback_entries")
