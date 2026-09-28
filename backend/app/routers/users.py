"""
/users — authentication + farmer profile.

Logout: JWTs are stateless, so "logout" is implemented as a client-side
token discard plus a server-side blocklist hook (see `revoked_tokens`
in-memory set below). For production, replace that set with a Redis-backed
blocklist keyed by token jti with TTL = token expiry.
"""
import os
import uuid

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from jose import JWTError
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, oauth2_scheme
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.config import settings
from app.database import get_db
from app.models.user import User, FarmerProfile
from app.schemas.user import (
    RegisterRequest,
    LoginRequest,
    TokenResponse,
    RefreshRequest,
    UserResponse,
    FarmerProfileUpdate,
    FarmerProfileResponse,
)

router = APIRouter(prefix="/users", tags=["users"])

# Simple in-memory revocation set for logout (MVP only — see module docstring).
_revoked_tokens: set[str] = set()


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    if payload.phone and db.query(User).filter(User.phone == payload.phone).first():
        raise HTTPException(status_code=400, detail="Phone number already registered")

    user = User(
        email=payload.email,
        phone=payload.phone,
        hashed_password=hash_password(payload.password),
        role=payload.role,
    )
    db.add(user)
    db.flush()  # get user.id before creating profile

    profile = FarmerProfile(user_id=user.id, full_name=payload.full_name)
    db.add(profile)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is deactivated")

    access_token = create_access_token(subject=str(user.id), extra_claims={"role": user.role.value})
    refresh_token = create_refresh_token(subject=str(user.id))
    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/refresh", response_model=TokenResponse)
def refresh(payload: RefreshRequest, db: Session = Depends(get_db)):
    try:
        decoded = decode_token(payload.refresh_token)
        if decoded.get("type") != "refresh" or payload.refresh_token in _revoked_tokens:
            raise HTTPException(status_code=401, detail="Invalid refresh token")
        user_id = decoded["sub"]
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    user = db.query(User).filter(User.id == uuid.UUID(user_id)).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    access_token = create_access_token(subject=str(user.id), extra_claims={"role": user.role.value})
    new_refresh_token = create_refresh_token(subject=str(user.id))
    return TokenResponse(access_token=access_token, refresh_token=new_refresh_token)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(token: str = Depends(oauth2_scheme), current_user: User = Depends(get_current_user)):
    _revoked_tokens.add(token)
    return None


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.put("/me/profile", response_model=FarmerProfileResponse)
def update_my_profile(
    payload: FarmerProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = current_user.farmer_profile
    if not profile:
        raise HTTPException(status_code=404, detail="Farmer profile not found")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)

    db.commit()
    db.refresh(profile)
    return profile


ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB


@router.post("/me/profile/image", response_model=FarmerProfileResponse)
async def upload_profile_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail="Only JPEG, PNG, or WEBP images are allowed")

    contents = await file.read()
    if len(contents) > MAX_IMAGE_SIZE_BYTES:
        raise HTTPException(status_code=400, detail="Image must be under 5MB")

    os.makedirs(settings.upload_dir, exist_ok=True)
    extension = file.filename.rsplit(".", 1)[-1] if "." in file.filename else "jpg"
    filename = f"profile_{current_user.id}.{extension}"
    filepath = os.path.join(settings.upload_dir, filename)
    with open(filepath, "wb") as f:
        f.write(contents)

    profile = current_user.farmer_profile
    profile.profile_image_url = f"/uploads/{filename}"
    db.commit()
    db.refresh(profile)
    return profile
