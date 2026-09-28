"""
Disease detection model-service abstraction.

WHY THIS EXISTS: the spec requires a real trained model architecture that can
be swapped in later, without pretending a mock is a real AI model. Every
prediction from the mock backend is explicitly tagged
`model_backend_used="mock"` in the DB record and the API response carries a
`is_mock_result` flag so the Flutter UI can show an honest "not a trained
model yet" notice if needed.

TO PLUG IN A REAL MODEL LATER:
  1. Implement a new class below (e.g. `TFLiteDiseaseModelService`) that
     subclasses `DiseaseModelService` and implements `predict()`.
  2. Register it in `get_disease_model_service()`.
  3. Set `DISEASE_MODEL_BACKEND=tflite` (or your chosen backend name) in .env.
No router or schema code needs to change.
"""
import hashlib
import random
from abc import ABC, abstractmethod
from dataclasses import dataclass, field

from app.config import settings

# Reference disease knowledge base used by the mock to produce plausible,
# consistent-looking results. A real model would replace this entirely with
# actual inference output — this dict is NOT a substitute for training data.
_KNOWN_DISEASES = {
    "Bacterial Leaf Blight": {
        "symptoms": ["Water-soaked stripes on leaf edges", "Yellowing leaves", "Wilting in severe cases"],
        "actions": [
            "Remove and destroy infected leaves",
            "Avoid overhead irrigation",
            "Apply a copper-based bactericide if available",
            "Improve field drainage",
        ],
    },
    "Leaf Blast": {
        "symptoms": ["Diamond-shaped lesions with gray centers", "Lesions on leaf collar and neck"],
        "actions": [
            "Reduce excess nitrogen fertilizer",
            "Apply a recommended fungicide",
            "Use resistant varieties in future planting",
        ],
    },
    "Powdery Mildew": {
        "symptoms": ["White powdery spots on leaves and stems", "Leaf curling", "Stunted growth"],
        "actions": [
            "Improve air circulation between plants",
            "Apply sulfur-based or neem-oil fungicide",
            "Avoid excess nitrogen fertilization",
        ],
    },
    "Healthy": {
        "symptoms": ["No visible signs of disease"],
        "actions": ["Continue regular monitoring", "Maintain current care routine"],
    },
}


@dataclass
class DiseasePrediction:
    disease_name: str
    confidence: float  # 0.0 - 1.0
    symptoms: list[str] = field(default_factory=list)
    recommended_actions: list[str] = field(default_factory=list)
    model_backend_used: str = "mock"
    is_mock_result: bool = True
    raw_output: str = ""


class DiseaseModelService(ABC):
    @abstractmethod
    def predict(self, image_bytes: bytes) -> DiseasePrediction:
        raise NotImplementedError


class MockDiseaseModelService(DiseaseModelService):
    """
    Deterministic-per-image mock: hashes the image bytes to pick a result, so
    the SAME uploaded image always returns the SAME mock prediction (useful
    for demoing and for tests), while different images vary.

    NOT a trained model. Do not present this as diagnostic-grade output.
    """

    def predict(self, image_bytes: bytes) -> DiseasePrediction:
        digest = hashlib.sha256(image_bytes).hexdigest()
        seeded_random = random.Random(digest)

        disease_name = seeded_random.choice(list(_KNOWN_DISEASES.keys()))
        info = _KNOWN_DISEASES[disease_name]
        confidence = round(seeded_random.uniform(0.55, 0.93), 2)

        return DiseasePrediction(
            disease_name=disease_name,
            confidence=confidence,
            symptoms=info["symptoms"],
            recommended_actions=info["actions"],
            model_backend_used="mock",
            is_mock_result=True,
            raw_output=f"mock:sha256={digest[:12]}",
        )


class UnimplementedRealModelService(DiseaseModelService):
    """Placeholder that fails loudly if a real backend is selected but not wired up yet."""

    def __init__(self, backend_name: str):
        self.backend_name = backend_name

    def predict(self, image_bytes: bytes) -> DiseasePrediction:
        raise NotImplementedError(
            f"DISEASE_MODEL_BACKEND='{self.backend_name}' is not implemented yet. "
            "Add a real implementation in app/services/disease_model_service.py "
            "and register it in get_disease_model_service()."
        )


def get_disease_model_service() -> DiseaseModelService:
    backend = settings.disease_model_backend.lower()
    if backend == "mock":
        return MockDiseaseModelService()
    # e.g. elif backend == "tflite": return TFLiteDiseaseModelService(settings.disease_model_path)
    return UnimplementedRealModelService(backend)
