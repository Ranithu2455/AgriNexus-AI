import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_farmer
from app.database import get_db
from app.models.farm import Farm
from app.models.user import User
from app.schemas.farm import FarmCreate, FarmUpdate, FarmResponse

router = APIRouter(prefix="/farms", tags=["farms"])


def _get_owned_farm_or_404(farm_id: uuid.UUID, current_user: User, db: Session) -> Farm:
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    if farm.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="You do not own this farm")
    return farm


@router.post("", response_model=FarmResponse, status_code=status.HTTP_201_CREATED)
def create_farm(
    payload: FarmCreate,
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    farm = Farm(owner_id=current_user.id, **payload.model_dump())
    db.add(farm)
    db.commit()
    db.refresh(farm)
    return farm


@router.get("", response_model=list[FarmResponse])
def list_my_farms(
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    return db.query(Farm).filter(Farm.owner_id == current_user.id).all()


@router.get("/{farm_id}", response_model=FarmResponse)
def get_farm(
    farm_id: uuid.UUID,
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    return _get_owned_farm_or_404(farm_id, current_user, db)


@router.put("/{farm_id}", response_model=FarmResponse)
def update_farm(
    farm_id: uuid.UUID,
    payload: FarmUpdate,
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    farm = _get_owned_farm_or_404(farm_id, current_user, db)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(farm, field, value)
    db.commit()
    db.refresh(farm)
    return farm


@router.delete("/{farm_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_farm(
    farm_id: uuid.UUID,
    current_user: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
):
    farm = _get_owned_farm_or_404(farm_id, current_user, db)
    db.delete(farm)
    db.commit()
    return None
