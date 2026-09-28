import uuid

from sqlalchemy import Column, String, DateTime, Float, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func

from app.database import Base


class DiseaseDetectionRecord(Base):
    """Stores each disease-detection request/result for history & audit."""
    __tablename__ = "disease_detection_records"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farmer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    crop_id = Column(UUID(as_uuid=True), ForeignKey("crops.id"), nullable=True, index=True)

    image_url = Column(String(500), nullable=False)
    predicted_disease = Column(String(150), nullable=True)
    confidence = Column(Float, nullable=True)
    symptoms = Column(JSONB, nullable=True)          # list[str]
    recommended_actions = Column(JSONB, nullable=True)  # list[str]
    model_backend_used = Column(String(50), nullable=False, default="mock")
    raw_model_output = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
