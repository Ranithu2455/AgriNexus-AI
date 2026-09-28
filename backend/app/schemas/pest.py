import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class PestDetectionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, protected_namespaces=())

    id: uuid.UUID
    image_url: str
    predicted_pest: Optional[str] = None
    confidence: Optional[float] = None
    symptoms: Optional[list[str]] = None
    recommended_actions: Optional[list[str]] = None
    model_backend_used: str
    is_mock_result: bool
    disclaimer: str = (
        "This AI result is not guaranteed to be accurate. "
        "Please consult an agricultural expert before taking major action."
    )
    created_at: datetime
