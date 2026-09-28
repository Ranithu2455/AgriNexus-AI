import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, ConfigDict

from app.models.farm import WaterAvailability


class FarmBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=150)
    location: Optional[str] = Field(None, max_length=255)
    district: Optional[str] = Field(None, max_length=100)
    size_acres: Optional[float] = Field(None, ge=0)
    soil_info: Optional[str] = Field(None, max_length=500)
    water_availability: WaterAvailability = WaterAvailability.MODERATE


class FarmCreate(FarmBase):
    pass


class FarmUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=150)
    location: Optional[str] = Field(None, max_length=255)
    district: Optional[str] = Field(None, max_length=100)
    size_acres: Optional[float] = Field(None, ge=0)
    soil_info: Optional[str] = Field(None, max_length=500)
    water_availability: Optional[WaterAvailability] = None


class FarmResponse(FarmBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    owner_id: uuid.UUID
    created_at: datetime
    updated_at: datetime
