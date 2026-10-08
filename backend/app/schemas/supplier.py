from pydantic import BaseModel


class SellerSummary(BaseModel):
    id: str
    full_name: str
    role: str
    location: str | None = None
    phone_number: str | None = None

    class Config:
        from_attributes = True
