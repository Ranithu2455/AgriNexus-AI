import os
import uuid

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session

from app.config import settings
from app.core.dependencies import get_current_farmer
from app.database import get_db
from app.models.pest import PestDetectionRecord
from app.models.user import User
from app.schemas.pest import PestDetectionResponse
from app.services.pest_model_service import get_pest_model_service

router = APIRouter(prefix="/pest-detection", tags=["pest-detection"])

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_IMAGE_SIZE_BYTES = 8 * 1024 * 1024


@router.post("", response_model=PestDetectionResponse, status_code=201)
async def detect_pest(
    file: UploadFile = File(...),
    crop_id: uuid.UUID | None = Form(None),
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail="Only JPEG, PNG, or WEBP images are allowed")

    contents = await file.read()
    if len(contents) > MAX_IMAGE_SIZE_BYTES:
        raise HTTPException(status_code=400, detail="Image must be under 8MB")
    if len(contents) == 0:
        raise HTTPException(status_code=400, detail="Uploaded file is empty")

    upload_dir = os.path.join(settings.upload_dir, "pest")
    os.makedirs(upload_dir, exist_ok=True)
    extension = file.filename.rsplit(".", 1)[-1] if file.filename and "." in file.filename else "jpg"
    filename = f"{uuid.uuid4()}.{extension}"
    filepath = os.path.join(upload_dir, filename)
    with open(filepath, "wb") as f:
        f.write(contents)
    image_url = f"/uploads/pest/{filename}"

    model_service = get_pest_model_service()
    try:
        prediction = model_service.predict(contents)
    except NotImplementedError as exc:
        raise HTTPException(status_code=503, detail=str(exc))

    record = PestDetectionRecord(
        farmer_id=current_user.id,
        crop_id=crop_id,
        image_url=image_url,
        predicted_pest=prediction.pest_name,
        confidence=prediction.confidence,
        symptoms=prediction.symptoms,
        recommended_actions=prediction.recommended_actions,
        model_backend_used=prediction.model_backend_used,
        raw_model_output=prediction.raw_output,
    )
    db.add(record)
    db.commit()
    db.refresh(record)

    return PestDetectionResponse(
        id=record.id,
        image_url=record.image_url,
        predicted_pest=record.predicted_pest,
        confidence=record.confidence,
        symptoms=record.symptoms,
        recommended_actions=record.recommended_actions,
        model_backend_used=record.model_backend_used,
        is_mock_result=prediction.is_mock_result,
        created_at=record.created_at,
    )


@router.get("/history", response_model=list[PestDetectionResponse])
def get_detection_history(
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    records = (
        db.query(PestDetectionRecord)
        .filter(PestDetectionRecord.farmer_id == current_user.id)
        .order_by(PestDetectionRecord.created_at.desc())
        .all()
    )
    return [
        PestDetectionResponse(
            id=r.id,
            image_url=r.image_url,
            predicted_pest=r.predicted_pest,
            confidence=r.confidence,
            symptoms=r.symptoms,
            recommended_actions=r.recommended_actions,
            model_backend_used=r.model_backend_used,
            is_mock_result=(r.model_backend_used == "mock"),
            created_at=r.created_at,
        )
        for r in records
    ]
