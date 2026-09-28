"""
Pest identification model-service abstraction — mirrors
disease_model_service.py exactly. See that file's docstring for how to plug
in a real trained model later.
"""
import hashlib
import random
from abc import ABC, abstractmethod
from dataclasses import dataclass, field

from app.config import settings

_KNOWN_PESTS = {
    "Brown Planthopper": {
        "symptoms": ["Yellowing and drying of lower leaves", "'Hopperburn' patches in the field"],
        "actions": [
            "Drain the field temporarily if waterlogged",
            "Avoid excess nitrogen fertilizer",
            "Use a recommended insecticide only if the population exceeds threshold",
            "Encourage natural predators (spiders, mirid bugs)",
        ],
    },
    "Fall Armyworm": {
        "symptoms": ["Ragged holes in leaves", "Sawdust-like frass near the whorl", "Damaged growing points"],
        "actions": [
            "Hand-pick larvae in small plots",
            "Apply a recommended biopesticide (e.g. Bt-based) early morning or evening",
            "Rotate crops to break the pest cycle",
        ],
    },
    "Aphids": {
        "symptoms": ["Curling or yellowing leaves", "Sticky honeydew residue", "Clusters of small insects under leaves"],
        "actions": [
            "Spray with a strong jet of water to dislodge aphids",
            "Introduce or conserve natural predators like ladybirds",
            "Use insecticidal soap or neem oil for heavy infestations",
        ],
    },
    "No Pest Detected": {
        "symptoms": ["No visible pest damage"],
        "actions": ["Continue regular field monitoring"],
    },
}


@dataclass
class PestPrediction:
    pest_name: str
    confidence: float
    symptoms: list[str] = field(default_factory=list)
    recommended_actions: list[str] = field(default_factory=list)
    model_backend_used: str = "mock"
    is_mock_result: bool = True
    raw_output: str = ""


class PestModelService(ABC):
    @abstractmethod
    def predict(self, image_bytes: bytes) -> PestPrediction:
        raise NotImplementedError


class MockPestModelService(PestModelService):
    """NOT a trained model — see disease_model_service.py docstring."""

    def predict(self, image_bytes: bytes) -> PestPrediction:
        digest = hashlib.sha256(image_bytes).hexdigest()
        seeded_random = random.Random(digest)

        pest_name = seeded_random.choice(list(_KNOWN_PESTS.keys()))
        info = _KNOWN_PESTS[pest_name]
        confidence = round(seeded_random.uniform(0.55, 0.93), 2)

        return PestPrediction(
            pest_name=pest_name,
            confidence=confidence,
            symptoms=info["symptoms"],
            recommended_actions=info["actions"],
            model_backend_used="mock",
            is_mock_result=True,
            raw_output=f"mock:sha256={digest[:12]}",
        )


class UnimplementedRealPestModelService(PestModelService):
    def __init__(self, backend_name: str):
        self.backend_name = backend_name

    def predict(self, image_bytes: bytes) -> PestPrediction:
        raise NotImplementedError(
            f"PEST_MODEL_BACKEND='{self.backend_name}' is not implemented yet. "
            "Add a real implementation in app/services/pest_model_service.py "
            "and register it in get_pest_model_service()."
        )


def get_pest_model_service() -> PestModelService:
    backend = settings.pest_model_backend.lower()
    if backend == "mock":
        return MockPestModelService()
    return UnimplementedRealPestModelService(backend)
