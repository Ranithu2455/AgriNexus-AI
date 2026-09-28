"""
SQLAlchemy engine + session setup.

NOTE for repo integration: if Member 2/3 already have a `database.py` with a
shared `Base` and `get_db`, DELETE this file and import theirs instead in all
Module 1 files (models, routers). This file exists so Module 1 works
standalone until the team merges shared infra.
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from app.config import settings

engine = create_engine(settings.database_url, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """FastAPI dependency that yields a DB session and always closes it."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
