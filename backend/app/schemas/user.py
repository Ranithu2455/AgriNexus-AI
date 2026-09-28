import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, ConfigDict

from app.models.user import UserRole


# ---------- Auth ----------

class RegisterRequest(BaseModel):
    email: EmailStr
    phone: Optional[str] = Field(None, max_length=20)
    password: str = Field(..., min_length=8, description="Minimum 8 characters")
    full_name: str = Field(..., min_length=2, max_length=150)
    role: UserRole = UserRole.FARMER


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


# ---------- Farmer Profile ----------

class FarmerProfileBase(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=150)
    district: Optional[str] = Field(None, max_length=100)
    location: Optional[str] = Field(None, max_length=255)
    farmer_info: Optional[str] = Field(None, max_length=1000)


class FarmerProfileUpdate(BaseModel):
    full_name: Optional[str] = Field(None, min_length=2, max_length=150)
    district: Optional[str] = Field(None, max_length=100)
    location: Optional[str] = Field(None, max_length=255)
    farmer_info: Optional[str] = Field(None, max_length=1000)


class FarmerProfileResponse(FarmerProfileBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    profile_image_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    phone: Optional[str] = None
    role: UserRole
    is_active: bool
    created_at: datetime
    farmer_profile: Optional[FarmerProfileResponse] = None
