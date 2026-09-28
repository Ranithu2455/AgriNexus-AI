import enum
import uuid

from sqlalchemy import Column, String, DateTime, Date, Enum, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class CropStatus(str, enum.Enum):
    PLANNED = "planned"
    PLANTED = "planted"
    GROWING = "growing"
    READY_FOR_HARVEST = "ready_for_harvest"
    HARVESTED = "harvested"
    FAILED = "failed"


class Crop(Base):
    __tablename__ = "crops"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farms.id"), nullable=False, index=True)

    name = Column(String(150), nullable=False)
    planting_date = Column(Date, nullable=True)
    expected_harvest_date = Column(Date, nullable=True)
    status = Column(Enum(CropStatus), default=CropStatus.PLANNED, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    farm = relationship("Farm", back_populates="crops")
    history_entries = relationship(
        "CropHistoryEntry", back_populates="crop", cascade="all, delete-orphan",
        order_by="CropHistoryEntry.recorded_at",
    )


class CropHistoryEntry(Base):
    """Append-only log of status changes / notable events for a crop."""
    __tablename__ = "crop_history_entries"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    crop_id = Column(UUID(as_uuid=True), ForeignKey("crops.id"), nullable=False, index=True)

    event = Column(String(150), nullable=False)  # e.g. "status_changed", "note"
    details = Column(Text, nullable=True)
    recorded_at = Column(DateTime(timezone=True), server_default=func.now())

    crop = relationship("Crop", back_populates="history_entries")
