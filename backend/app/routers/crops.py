import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.core.dependencies import get_current_farmer
from app.database import get_db
from app.models.crop import Crop, CropHistoryEntry
from app.models.farm import Farm
from app.models.user import User
from app.schemas.crop import CropCreate, CropUpdate, CropResponse, CropDetailResponse

router = APIRouter(prefix="/crops", tags=["crops"])


def _get_owned_crop_or_404(crop_id: uuid.UUID, current_user: User, db: Session) -> Crop:
    crop = (
        db.query(Crop)
        .options(joinedload(Crop.farm))
        .filter(Crop.id == crop_id)
        .first()
    )
    if not crop:
        raise HTTPException(status_code=404, detail="Crop not found")
    if crop.farm.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="You do not own this crop")
    return crop


def _assert_owns_farm(farm_id: uuid.UUID, current_user: User, db: Session) -> Farm:
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    if farm.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="You do not own this farm")
    return farm


@router.post("", response_model=CropResponse, status_code=status.HTTP_201_CREATED)
def create_crop(
    payload: CropCreate,
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    _assert_owns_farm(payload.farm_id, current_user, db)
    crop = Crop(**payload.model_dump())
    db.add(crop)
    db.flush()
    db.add(CropHistoryEntry(crop_id=crop.id, event="created", details=f"Status: {crop.status.value}"))
    db.commit()
    db.refresh(crop)
    return crop


@router.get("", response_model=list[CropResponse])
def list_my_crops(
    farm_id: uuid.UUID | None = None,
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    query = db.query(Crop).join(Farm).filter(Farm.owner_id == current_user.id)
    if farm_id:
        query = query.filter(Crop.farm_id == farm_id)
    return query.all()


@router.get("/{crop_id}", response_model=CropDetailResponse)
def get_crop(
    crop_id: uuid.UUID,
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    return _get_owned_crop_or_404(crop_id, current_user, db)


@router.put("/{crop_id}", response_model=CropResponse)
def update_crop(
    crop_id: uuid.UUID,
    payload: CropUpdate,
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    crop = _get_owned_crop_or_404(crop_id, current_user, db)
    updates = payload.model_dump(exclude_unset=True)

    if "status" in updates and updates["status"] != crop.status:
        db.add(CropHistoryEntry(
            crop_id=crop.id,
            event="status_changed",
            details=f"{crop.status.value} -> {updates['status'].value}",
        ))

    for field, value in updates.items():
        setattr(crop, field, value)

    db.commit()
    db.refresh(crop)
    return crop


@router.delete("/{crop_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_crop(
    crop_id: uuid.UUID,
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    crop = _get_owned_crop_or_404(crop_id, current_user, db)
    db.delete(crop)
    db.commit()
    return None
