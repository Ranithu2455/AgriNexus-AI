"""
Import every model here so Alembic's autogenerate (and Base.metadata.create_all)
can see all tables. Add new model modules to this list as they're created.
"""
from app.models.user import User, FarmerProfile, UserRole          # noqa: F401
from app.models.farm import Farm, WaterAvailability                # noqa: F401
from app.models.crop import Crop, CropHistoryEntry, CropStatus     # noqa: F401
from app.models.disease import DiseaseDetectionRecord               # noqa: F401
from app.models.pest import PestDetectionRecord                     # noqa: F401
from app.models.feedback import FarmerFeedback, FeedbackType        # noqa: F401
