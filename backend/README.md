# AgriNexus AI — Module 1: Farmer + AI Agriculture (Backend)

FastAPI backend for Module 1. Owns: `/users`, `/farms`, `/crops`,
`/disease-detection`, `/pest-detection`, `/crop-recommendations`,
`/weather`, `/farmer-feedback`.

Tested: 23/23 tests passing against a real PostgreSQL 16 database, plus a
live end-to-end smoke test (register → login → weather → crop recommendation
→ farm creation) run against the actual running server.

## 1. Setup

```bash
cd backend
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# edit .env: set DATABASE_URL, JWT_SECRET_KEY, WEATHER_API_KEY (optional)
```

## 2. Database

Create the Postgres database and user (match whatever Members 2 & 3 use if
a shared DB already exists — do NOT create a second one):

```bash
sudo -u postgres psql -c "CREATE USER agrinexus_user WITH PASSWORD 'changeme';"
sudo -u postgres psql -c "CREATE DATABASE agrinexus_db OWNER agrinexus_user;"
```

Create tables (MVP — no migration history needed yet):
```bash
python3 -c "from app.database import Base, engine; import app.models; Base.metadata.create_all(bind=engine)"
```

Or, to track schema changes with Alembic instead:
```bash
alembic revision --autogenerate -m "init module 1 tables"
alembic upgrade head
```

## 3. Run the server

```bash
uvicorn app.main:app --reload --port 8000
```

- API docs: http://localhost:8000/docs
- Health check: http://localhost:8000/health

## 4. Run tests

Tests need a real Postgres database (models use Postgres-specific
UUID/JSONB columns):

```bash
sudo -u postgres psql -c "CREATE DATABASE agrinexus_test_db OWNER agrinexus_user;"
export TEST_DATABASE_URL=postgresql://agrinexus_user:changeme@localhost:5432/agrinexus_test_db
pytest app/tests/ -v
```

## 5. AI features — mock vs real models

`DISEASE_MODEL_BACKEND` and `PEST_MODEL_BACKEND` in `.env` default to
`mock`. The mock is deterministic (same image → same result) and every
response is tagged `is_mock_result: true` with a disclaimer — it is NOT a
trained model and must not be presented as one.

To plug in a real trained model:
1. Add a new class in `app/services/disease_model_service.py` (or
   `pest_model_service.py`) implementing `predict(image_bytes) -> DiseasePrediction`.
2. Register it in `get_disease_model_service()`.
3. Set `DISEASE_MODEL_BACKEND=<your-backend-name>` in `.env`.

No router or schema code needs to change.

## 6. Integrating into the team's combined repo

- `app/database.py` defines its own `Base`/`get_db`/engine so Module 1 works
  standalone. If Member 2/3 already have shared DB infra, delete this file
  and repoint all imports (`models/`, `routers/`) at theirs.
- `app/models/user.py`'s `User` table is designed to be the ONE shared user
  table — `UserRole` already includes `buyer` and `community_member` for
  Modules 2 and 3. Coordinate before anyone else creates a separate users
  table.
- Only these prefixes are owned by this module: `/users`, `/farms`,
  `/crops`, `/disease-detection`, `/pest-detection`, `/crop-recommendations`,
  `/weather`, `/farmer-feedback`. Do not add Marketplace/Community routes
  here.

## API summary

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | /users/register | — | Register (creates User + FarmerProfile) |
| POST | /users/login | — | Login, returns JWT access+refresh tokens |
| POST | /users/refresh | — | Exchange refresh token for new tokens |
| POST | /users/logout | ✓ | Revoke current access token |
| GET | /users/me | ✓ | Current user + profile |
| PUT | /users/me/profile | ✓ | Update farmer profile |
| POST | /users/me/profile/image | ✓ | Upload profile image |
| POST/GET | /farms | ✓ | Create / list own farms |
| GET/PUT/DELETE | /farms/{id} | ✓ | Manage a single farm |
| POST/GET | /crops | ✓ | Create / list own crops |
| GET/PUT/DELETE | /crops/{id} | ✓ | Manage a single crop (with history log) |
| POST | /disease-detection | ✓ | Upload plant image → mock/real AI result |
| GET | /disease-detection/history | ✓ | Past disease detections |
| POST | /pest-detection | ✓ | Upload plant image → mock/real AI result |
| GET | /pest-detection/history | ✓ | Past pest detections |
| POST | /crop-recommendations | ✓ | Soil/climate inputs → ranked crop suggestions |
| GET | /weather | ✓ | Current weather + agri advisories for a location |
| POST/GET | /farmer-feedback | ✓ | Record / list field observations |
