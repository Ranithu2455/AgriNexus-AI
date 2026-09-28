"""
Module 1 (Farmer + AI Agriculture) FastAPI app.

Do NOT mount Marketplace or Community routers here — this app is meant to be
included into the team's combined app, e.g.:

    from app.main import app as farmer_app
    main_app.mount("/", farmer_app)   # or use a shared router aggregator

Run standalone for development with: uvicorn app.main:app --reload
"""
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import settings
from app.routers import (
    users,
    farms,
    crops,
    disease_detection,
    pest_detection,
    crop_recommendations,
    weather,
    farmer_feedback,
)

app = FastAPI(
    title="AgriNexus AI - Module 1: Farmer + AI Agriculture",
    description="Farmer auth, profiles, farms, crops, and AI-assisted agriculture features.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

os.makedirs(settings.upload_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.upload_dir), name="uploads")

app.include_router(users.router)
app.include_router(farms.router)
app.include_router(crops.router)
app.include_router(disease_detection.router)
app.include_router(pest_detection.router)
app.include_router(crop_recommendations.router)
app.include_router(weather.router)
app.include_router(farmer_feedback.router)


@app.get("/health", tags=["health"])
def health_check():
    return {"status": "ok", "module": "farmer-ai"}
