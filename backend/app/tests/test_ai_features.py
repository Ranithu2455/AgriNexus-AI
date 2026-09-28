import io


def test_crop_recommendation_returns_ranked_list(client, auth_headers):
    resp = client.post("/crop-recommendations", json={
        "soil_ph": 6.0,
        "nitrogen": 30,
        "phosphorus": 20,
        "potassium": 20,
        "temperature_c": 28,
        "humidity_pct": 70,
        "rainfall_mm": 200,
        "location": "Kurunegala",
        "season": "Maha",
        "water_availability": "abundant",
    }, headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert len(body["recommendations"]) > 0
    assert "disclaimer" in body
    scores = [r["suitability_score"] for r in body["recommendations"]]
    assert scores == sorted(scores, reverse=True)


def test_weather_endpoint_returns_advisories(client, auth_headers):
    resp = client.get("/weather", params={"location": "Kurunegala"}, headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert "advisories" in body
    assert len(body["advisories"]) > 0


def test_disease_detection_rejects_non_image(client, auth_headers):
    fake_file = io.BytesIO(b"not an image")
    resp = client.post(
        "/disease-detection",
        files={"file": ("test.txt", fake_file, "text/plain")},
        headers=auth_headers,
    )
    assert resp.status_code == 400


def test_disease_detection_accepts_image_and_flags_mock(client, auth_headers):
    fake_image = io.BytesIO(b"\xff\xd8\xff\xe0fakejpegcontent")
    resp = client.post(
        "/disease-detection",
        files={"file": ("leaf.jpg", fake_image, "image/jpeg")},
        headers=auth_headers,
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["is_mock_result"] is True
    assert body["predicted_disease"] is not None
    assert "disclaimer" in body


def test_pest_detection_accepts_image(client, auth_headers):
    fake_image = io.BytesIO(b"\xff\xd8\xff\xe0fakejpegcontent")
    resp = client.post(
        "/pest-detection",
        files={"file": ("bug.jpg", fake_image, "image/jpeg")},
        headers=auth_headers,
    )
    assert resp.status_code == 201
    assert resp.json()["is_mock_result"] is True


def test_farmer_feedback_create_and_list(client, auth_headers):
    resp = client.post("/farmer-feedback", json={
        "feedback_type": "drought",
        "description": "No rain for two weeks",
    }, headers=auth_headers)
    assert resp.status_code == 201

    list_resp = client.get("/farmer-feedback", headers=auth_headers)
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1
    assert list_resp.json()[0]["feedback_type"] == "drought"


def test_farmer_feedback_rejects_other_farmers_farm(client, auth_headers):
    client.post("/users/register", json={
        "email": "farmer3@example.com",
        "password": "securepass123",
        "full_name": "Third Farmer",
    })
    login = client.post("/users/login", json={
        "email": "farmer3@example.com",
        "password": "securepass123",
    })
    other_headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
    farm_resp = client.post("/farms", json={"name": "Other Farm"}, headers=other_headers)
    other_farm_id = farm_resp.json()["id"]

    resp = client.post("/farmer-feedback", json={
        "feedback_type": "pest_outbreak",
        "farm_id": other_farm_id,
    }, headers=auth_headers)
    assert resp.status_code == 403
