from fastapi import APIRouter, Depends, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.models.user import User
from app.database import get_db
from app.models.product import Category, Listing, ListingImage, Inquiry
from app.core.permissions import assert_can_sell, assert_owns_listing
from app.schemas.product import InquiryCreate, InquiryOut, ListingCreate, ListingImageOut, ListingOut, ListingUpdate
from app.services.image_service import get_image_storage, validate_and_read_image

router = APIRouter(prefix="/api/listings", tags=["listings"])


@router.post("", response_model=ListingOut, status_code=status.HTTP_201_CREATED)
def create_listing(
    payload: ListingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    assert_can_sell(current_user)

    category = db.query(Category).filter(Category.id == payload.category_id).first()
    if not category:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid category_id")

    listing = Listing(seller_id=current_user.id, **payload.model_dump())
    db.add(listing)
    db.commit()
    db.refresh(listing)
    return listing


@router.get("/my", response_model=list[ListingOut])
def my_listings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(Listing)
        .filter(Listing.seller_id == current_user.id)
        .order_by(Listing.created_at.desc())
        .all()
    )


@router.get("/{listing_id}", response_model=ListingOut)
def get_listing(listing_id: str, db: Session = Depends(get_db)):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    return listing


@router.put("/{listing_id}", response_model=ListingOut)
def update_listing(
    listing_id: str,
    payload: ListingUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    assert_owns_listing(listing, current_user)

    if payload.category_id is not None:
        category = db.query(Category).filter(Category.id == payload.category_id).first()
        if not category:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid category_id")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(listing, field, value)

    db.commit()
    db.refresh(listing)
    return listing


@router.delete("/{listing_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_listing(
    listing_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    assert_owns_listing(listing, current_user)

    db.delete(listing)
    db.commit()
    return None


@router.post("/{listing_id}/images", response_model=ListingImageOut, status_code=status.HTTP_201_CREATED)
async def upload_listing_image(
    listing_id: str,
    file: UploadFile,
    set_primary: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    assert_owns_listing(listing, current_user)

    contents = await validate_and_read_image(file)
    storage = get_image_storage()
    image_url = storage.save(file, contents)

    if set_primary:
        for img in listing.images:
            img.is_primary = False

    image = ListingImage(listing_id=listing.id, image_url=image_url, is_primary=set_primary)
    db.add(image)
    db.commit()
    db.refresh(image)
    return image


@router.delete("/{listing_id}/images/{image_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_listing_image(
    listing_id: str,
    image_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    assert_owns_listing(listing, current_user)

    image = db.query(ListingImage).filter(
        ListingImage.id == image_id, ListingImage.listing_id == listing_id
    ).first()
    if not image:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found")

    db.delete(image)
    db.commit()
    return None


@router.post("/{listing_id}/inquiries", response_model=InquiryOut, status_code=status.HTTP_201_CREATED)
def send_inquiry(
    listing_id: str,
    payload: InquiryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    if listing.seller_id == current_user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You cannot inquire about your own listing")

    inquiry = Inquiry(listing_id=listing.id, buyer_id=current_user.id, message=payload.message)
    db.add(inquiry)
    db.commit()
    db.refresh(inquiry)
    return inquiry


@router.get("/{listing_id}/inquiries", response_model=list[InquiryOut])
def list_inquiries_for_listing(
    listing_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    assert_owns_listing(listing, current_user)

    return (
        db.query(Inquiry)
        .filter(Inquiry.listing_id == listing_id)
        .order_by(Inquiry.created_at.desc())
        .all()
    )
