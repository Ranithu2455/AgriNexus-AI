from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.user import User
from app.database import get_db
from app.models.order import Review
from app.models.product import Category, Listing, ListingStatus, ListingType
from app.schemas.product import ListingDetailOut, PaginatedListings
from app.schemas.supplier import SellerSummary

router = APIRouter(prefix="/api/products", tags=["products"])


@router.get("", response_model=PaginatedListings)
def browse_products(
    q: str | None = Query(default=None, description="Free-text search over title/description"),
    category_id: str | None = None,
    listing_type: ListingType | None = None,
    seller_id: str | None = Query(default=None, description="Filter to one seller's active listings"),
    location: str | None = None,
    min_price: float | None = Query(default=None, ge=0),
    max_price: float | None = Query(default=None, ge=0),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    """
    Buyer-facing browse/search/filter endpoint. Only ever returns listings
    that are currently `active` — an empty or filtered-to-nothing result set
    is a normal, valid response, not an error.
    """
    query = db.query(Listing).filter(Listing.status == ListingStatus.active)

    if q:
        like = f"%{q}%"
        query = query.filter((Listing.title.ilike(like)) | (Listing.description.ilike(like)))
    if category_id:
        query = query.filter(Listing.category_id == category_id)
    if seller_id:
        query = query.filter(Listing.seller_id == seller_id)
    if listing_type:
        query = query.filter(Listing.listing_type == listing_type)
    if location:
        query = query.filter(Listing.location.ilike(f"%{location}%"))
    if min_price is not None:
        query = query.filter(Listing.price >= min_price)
    if max_price is not None:
        query = query.filter(Listing.price <= max_price)

    total = query.count()
    items = (
        query.order_by(Listing.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )
    return PaginatedListings(items=items, total=total, page=page, page_size=page_size)


@router.get("/{listing_id}", response_model=ListingDetailOut)
def get_product_details(listing_id: str, db: Session = Depends(get_db)):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    seller = db.query(User).filter(User.id == listing.seller_id).first()
    category = db.query(Category).filter(Category.id == listing.category_id).first()

    rating_row = (
        db.query(func.avg(Review.rating), func.count(Review.id))
        .filter(Review.reviewee_id == listing.seller_id)
        .first()
    )
    average_rating = float(rating_row[0]) if rating_row and rating_row[0] is not None else None
    review_count = int(rating_row[1]) if rating_row else 0

    return ListingDetailOut(
        **{c.name: getattr(listing, c.name) for c in listing.__table__.columns},
        images=listing.images,
        seller=SellerSummary.model_validate(seller),
        category=category,
        average_rating=average_rating,
        review_count=review_count,
    )
