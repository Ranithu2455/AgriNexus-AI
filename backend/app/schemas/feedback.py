import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, ConfigDict

from app.models.feedback import FeedbackType


class FarmerFeedbackCreate(BaseModel):
    feedback_type: FeedbackType
    description: Optional[str] = Field(None, max_length=2000)
    farm_id: Optional[uuid.UUID] = None
    crop_id: Optional[uuid.UUID] = None


class FarmerFeedbackResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    feedback_type: FeedbackType
    description: Optional[str] = None
    farm_id: Optional[uuid.UUID] = None
    crop_id: Optional[uuid.UUID] = None
    created_at: datetime
