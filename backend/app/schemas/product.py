from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field, field_validator

from app.models.product import ListingStatus, ListingType
from app.models.supplier import SupplierProductType
from app.schemas.supplier import SellerSummary


class CategoryCreate(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    slug: str = Field(min_length=1, max_length=160)
    description: str | None = None
    parent_id: str | None = None


class CategoryOut(BaseModel):
    id: str
    name: str
    slug: str
    description: str | None
    parent_id: str | None

    class Config:
        from_attributes = True


class ListingImageOut(BaseModel):
    id: str
    image_url: str
    is_primary: bool

    class Config:
        from_attributes = True


class ListingBase(BaseModel):
    category_id: str
    listing_type: ListingType = ListingType.farmer_product
    supplier_product_type: SupplierProductType | None = None
    title: str = Field(min_length=1, max_length=200)
    description: str | None = None
    quantity: Decimal = Field(gt=0)
    unit: str = Field(min_length=1, max_length=30)
    price: Decimal = Field(gt=0)
    currency: str = Field(default="LKR", max_length=10)
    location: str | None = None
    available_date: datetime | None = None

    @field_validator("supplier_product_type")
    @classmethod
    def supplier_type_requires_supplier_listing(cls, v, info):
        listing_type = info.data.get("listing_type")
        if listing_type == ListingType.supplier_product and v is None:
            raise ValueError("supplier_product_type is required when listing_type is supplier_product")
        if listing_type == ListingType.farmer_product and v is not None:
            raise ValueError("supplier_product_type must be omitted for farmer_product listings")
        return v


class ListingCreate(ListingBase):
    pass


class ListingUpdate(BaseModel):
    category_id: str | None = None
    title: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = None
    quantity: Decimal | None = Field(default=None, gt=0)
    unit: str | None = None
    price: Decimal | None = Field(default=None, gt=0)
    location: str | None = None
    available_date: datetime | None = None
    status: ListingStatus | None = None


class ListingOut(ListingBase):
    id: str
    seller_id: str
    status: ListingStatus
    created_at: datetime
    updated_at: datetime
    images: list[ListingImageOut] = []

    class Config:
        from_attributes = True


class ListingDetailOut(ListingOut):
    """Listing + seller info, used for the product-details screen."""
    seller: SellerSummary
    category: CategoryOut
    average_rating: float | None = None
    review_count: int = 0


class PaginatedListings(BaseModel):
    items: list[ListingOut]
    total: int
    page: int
    page_size: int


class InquiryCreate(BaseModel):
    message: str = Field(min_length=1, max_length=2000)


class InquiryOut(BaseModel):
    id: str
    listing_id: str
    buyer_id: str
    message: str
    created_at: datetime

    class Config:
        from_attributes = True
