import uuid
from datetime import date, datetime
from typing import Optional, List

from pydantic import BaseModel, Field, ConfigDict

from app.models.crop import CropStatus


class CropBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=150)
    planting_date: Optional[date] = None
    expected_harvest_date: Optional[date] = None
    status: CropStatus = CropStatus.PLANNED


class CropCreate(CropBase):
    farm_id: uuid.UUID


class CropUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=150)
    planting_date: Optional[date] = None
    expected_harvest_date: Optional[date] = None
    status: Optional[CropStatus] = None


class CropHistoryEntryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    event: str
    details: Optional[str] = None
    recorded_at: datetime


class CropResponse(CropBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    farm_id: uuid.UUID
    created_at: datetime
    updated_at: datetime


class CropDetailResponse(CropResponse):
    history_entries: List[CropHistoryEntryResponse] = []
