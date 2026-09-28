"""
Centralized app configuration, loaded from environment variables (.env).
Import `settings` anywhere you need config values — never hard-code secrets.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Database
    database_url: str = "postgresql://agrinexus_user:changeme@localhost:5432/agrinexus_db"

    # Auth
    jwt_secret_key: str = "dev-secret-change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 7

    # Weather
    weather_api_key: str = ""
    weather_api_base_url: str = "https://api.openweathermap.org/data/2.5"

    # AI model backends
    disease_model_backend: str = "mock"  # mock | tflite | torchserve
    pest_model_backend: str = "mock"
    disease_model_path: str = "./models/disease_model.tflite"
    pest_model_path: str = "./models/pest_model.tflite"

    # App
    environment: str = "development"
    cors_origins: str = "http://localhost:3000,http://localhost:8080"
    upload_dir: str = "./uploads"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


settings = Settings()
