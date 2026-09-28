"""
Test fixtures.

Requires a real Postgres test database (UUID/JSONB columns are Postgres-
specific, so SQLite can't be substituted here). Point TEST_DATABASE_URL at a
throwaway DB before running pytest, e.g.:

    export TEST_DATABASE_URL=postgresql://agrinexus_user:changeme@localhost:5432/agrinexus_test_db
    pytest
"""
import os

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

import app.models  # noqa: F401 - register all models on Base.metadata (import BEFORE app.main's `app` name)
from app.database import Base, get_db
from app.main import app

TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql://agrinexus_user:changeme@localhost:5432/agrinexus_test_db",
)

engine = create_engine(TEST_DATABASE_URL)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="function")
def db_session():
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def client(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def registered_farmer(client):
    payload = {
        "email": "farmer1@example.com",
        "phone": "+94771234567",
        "password": "securepass123",
        "full_name": "Nimal Perera",
        "role": "farmer",
    }
    resp = client.post("/users/register", json=payload)
    assert resp.status_code == 201
    return payload


@pytest.fixture
def auth_headers(client, registered_farmer):
    resp = client.post("/users/login", json={
        "email": registered_farmer["email"],
        "password": registered_farmer["password"],
    })
    assert resp.status_code == 200
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
