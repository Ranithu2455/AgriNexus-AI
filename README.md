# AgriNexus AI

A smart agriculture platform for Sri Lankan farmers, built as a university group project.

| | |
|---|---|
| **Frontend** | Flutter (Dart) — Android + iOS |
| **Backend** | Python, FastAPI |
| **Database** | PostgreSQL |
| **AI/ML** | Python (TensorFlow / PyTorch / TFLite, pluggable) |
| **Languages** | English, Sinhala (සිංහල), Tamil (தமிழ்) |

---

## Modules and ownership

| # | Module | Owner | Status |
|---|---|---|---|
| 1 | Farmer + AI Agriculture | Member 1 (`member1/farmer-ai`) | Implemented — see below |
| 2 | Marketplace | Member 2 | Not in this branch |
| 3 | Communication + Community | Member 3 | Not in this branch |

Each member works on their own branch and only touches their own module.

---

## Repository structure

```
AgriNexus-AI/
├── README.md               ← this file
├── backend/                ← FastAPI app (see backend/README.md)
│   ├── app/
│   │   ├── main.py         ← app entry, mounts routers
│   │   ├── config.py       ← env-based settings
│   │   ├── database.py     ← SQLAlchemy engine/session
│   │   ├── core/           ← JWT, password hashing, auth dependencies
│   │   ├── models/         ← SQLAlchemy tables
│   │   ├── schemas/        ← Pydantic request/response models
│   │   ├── routers/        ← API endpoints
│   │   ├── services/       ← AI model abstractions, recommendation, weather
│   │   └── tests/          ← pytest suite
│   ├── alembic/            ← migration scaffolding
│   ├── requirements.txt
│   └── .env.example
└── frontend/               ← Flutter app (see frontend/README.md)
    ├── pubspec.yaml
    ├── l10n.yaml
    └── lib/
        ├── main.dart
        ├── shared/         ← API client, models, services, state, widgets, l10n
        └── features/       ← one folder per feature area
```

---

## Module 1 — Farmer + AI Agriculture

### Features

- **Authentication** — register, login, logout, refresh tokens, roles, bcrypt password hashing, JWT
- **Farmer profile** — name, phone, email, district, location, profile image, farmer info
- **Farm management** — create / edit / delete farms (size, soil info, water availability)
- **Crop management** — add / edit / delete crops, status tracking, automatic crop history log
- **AI plant disease detection** — image upload → disease, confidence, symptoms, recommended actions
- **Pest identification** — same architecture as disease detection
- **AI crop recommendation** — soil/climate inputs → ranked crops with reasons and warnings
- **Weather** — location-based weather plus rule-based agricultural advice
- **Farmer feedback** — record field observations (waterlogging, drought, salinity, pest/disease outbreak, etc.)

### Backend API ownership

Module 1 owns these route prefixes only:

| Prefix | Purpose |
|---|---|
| `/users` | Register, login, refresh, logout, `/me`, profile, profile image |
| `/farms` | Farm CRUD |
| `/crops` | Crop CRUD + history |
| `/disease-detection` | Upload image, get result, `/history` |
| `/pest-detection` | Upload image, get result, `/history` |
| `/crop-recommendations` | Soil/climate inputs → ranked suggestions |
| `/weather` | Current weather + advisories (`GET /weather?location=...`) |
| `/farmer-feedback` | Create / list observations |

Interactive docs are available at `http://localhost:8000/docs` when the backend is running.

### Flutter screens

Login, Register, Farmer Dashboard, Farmer Profile, My Farms, Add/Edit Farm, Farm Details, My Crops, Add Crop, Crop Details, AI Plant Doctor, Disease Result, Pest Identification, Crop Recommendation, Weather, Farmer Feedback.

---

## Important notes on the AI features

**The disease and pest detection models are mocks.** No trained model exists yet. The mock backend is deterministic (same image always gives the same result), and every API response carries `is_mock_result: true` plus a disclaimer. The Flutter UI shows a visible "demo mode" notice for mock results. It must not be presented as a real trained model.

To plug in a real model later:

1. Add a class implementing `predict(image_bytes)` in `backend/app/services/disease_model_service.py` (or `pest_model_service.py`)
2. Register it in `get_disease_model_service()` / `get_pest_model_service()`
3. Set `DISEASE_MODEL_BACKEND` / `PEST_MODEL_BACKEND` in `.env`

No router, schema, or Flutter code needs to change.

**Crop recommendation is a transparent rule-based scoring engine**, not a trained ML model. It scores 8 common Sri Lankan crops against soil pH, temperature, rainfall, water availability, and season, and explains every score. It is decision support, not guaranteed agricultural advice.

**Weather** uses OpenWeatherMap when `WEATHER_API_KEY` is set. Without a key (or if the external API fails), it falls back to a clearly labelled mock response so the app still works.

---

## Quick start

### Prerequisites (macOS)

- Flutter SDK, VS Code with the Flutter + Dart extensions
- Xcode + CocoaPods (iOS builds)
- Android Studio (Android SDK + emulator)
- Python 3.12+
- PostgreSQL 16

```bash
xcode-select --install
sudo gem install cocoapods
brew install postgresql@16
brew services start postgresql@16
flutter doctor
```

### 1. Backend

```bash
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # edit DATABASE_URL and JWT_SECRET_KEY

createuser agrinexus_user -P    # password: changeme (or update .env to match)
createdb agrinexus_db -O agrinexus_user

python3 -c "from app.database import Base, engine; import app.models; Base.metadata.create_all(bind=engine)"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Check `http://localhost:8000/health`.

### 2. Frontend

```bash
cd frontend
flutter create --org com.agrinexus --project-name agrinexus_farmer .   # only if android/ios folders are missing
flutter pub get
flutter analyze
```

Add platform permissions (details in `frontend/README.md`): camera + internet on Android, camera + photo library descriptions on iOS.

Run against the backend (the base URL differs per platform):

```bash
# iOS Simulator
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:8000

# Android emulator (10.0.2.2 is the emulator's alias for your Mac)
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Physical device: use your Mac's LAN IP
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8000
```

### 3. Tests (backend)

```bash
createdb agrinexus_test_db -O agrinexus_user
export TEST_DATABASE_URL=postgresql://agrinexus_user:changeme@localhost:5432/agrinexus_test_db
cd backend && pytest app/tests/ -v
```

---

## Verification status

| Area | Status |
|---|---|
| Backend tests | 23/23 passing against real PostgreSQL 16 |
| Backend live smoke test | Register, login, weather, crop recommendation, farm creation verified against a running server |
| Frontend ↔ backend contract | Every API path and request/response field checked against the backend schemas |
| Flutter app compile/run | **Not yet verified** — run `flutter analyze` and `flutter run` and fix anything they report before demoing |

---

## Integration notes for Members 2 and 3

- **One shared `users` table.** `backend/app/models/user.py` is the single user table. `UserRole` already includes `buyer` and `community_member`. Do not create a second user system; reference `users.id` (UUID) as a foreign key.
- **Shared infrastructure.** `backend/app/database.py` defines `Base`, `get_db`, and the engine. `backend/app/core/dependencies.py` provides `get_current_user` and `require_role(...)`. Reuse them.
- **Dependency pins matter.** `bcrypt==4.0.1` is pinned because `passlib==1.7.4` breaks with newer bcrypt versions (every register/login fails). Don't upgrade it independently.
- **Frontend shared code.** Put cross-cutting code under `frontend/lib/shared/`. Reuse `ApiClient`, `TokenStorage`, and the common widgets rather than duplicating them.
- **Localization.** All user-facing strings go through the ARB files in `frontend/lib/shared/l10n/` (English, Sinhala, Tamil). Don't hard-code strings in widgets.
- **Route ownership.** Don't add Marketplace or Community routes under Module 1's prefixes, and don't edit another member's module.

---

## Git workflow

```bash
git checkout -b member1/farmer-ai        # your module branch
git add backend/ frontend/
git commit -m "Module 1: Farmer + AI Agriculture"
git push origin member1/farmer-ai
```

Open a pull request into `main` when a module is ready. Pull `main` regularly so shared files (`database.py`, `requirements.txt`, `pubspec.yaml`) don't drift.

---

## Environment variables

Copy `backend/.env.example` to `backend/.env`. Never commit `.env` or hard-code keys.

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string (shared with other modules) |
| `JWT_SECRET_KEY` | Secret for signing tokens — use a long random value |
| `ACCESS_TOKEN_EXPIRE_MINUTES` / `REFRESH_TOKEN_EXPIRE_DAYS` | Token lifetimes |
| `WEATHER_API_KEY` | OpenWeatherMap key (optional; mock fallback without it) |
| `DISEASE_MODEL_BACKEND` / `PEST_MODEL_BACKEND` | `mock` now; set to your backend name when a real model exists |
| `CORS_ORIGINS`, `UPLOAD_DIR` | CORS allow-list and image upload folder |

---

## Known limitations

- Logout revokes tokens in an in-memory set (fine for a single dev server; use Redis or a DB table for production)
- Uploaded images are stored on local disk under `uploads/`
- The dev setup uses plain HTTP; use HTTPS before any real deployment
- Flutter app has not been compiled in the environment it was written in (see Verification status)
