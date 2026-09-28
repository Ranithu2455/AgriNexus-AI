import pytest


@pytest.fixture
def a_farm(client, auth_headers):
    resp = client.post("/farms", json={"name": "Crop Test Farm"}, headers=auth_headers)
    return resp.json()


def test_create_crop(client, auth_headers, a_farm):
    resp = client.post("/crops", json={
        "name": "Rice",
        "farm_id": a_farm["id"],
        "planting_date": "2026-05-01",
        "expected_harvest_date": "2026-09-01",
    }, headers=auth_headers)
    assert resp.status_code == 201
    assert resp.json()["name"] == "Rice"
    assert resp.json()["status"] == "planned"


def test_create_crop_rejects_other_farmer_farm(client, auth_headers, a_farm):
    # Register a second farmer and try to add a crop to the first farmer's farm
    client.post("/users/register", json={
        "email": "farmer2@example.com",
        "password": "securepass123",
        "full_name": "Second Farmer",
    })
    login = client.post("/users/login", json={
        "email": "farmer2@example.com",
        "password": "securepass123",
    })
    other_headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

    resp = client.post("/crops", json={"name": "Rice", "farm_id": a_farm["id"]}, headers=other_headers)
    assert resp.status_code == 403


def test_crop_status_change_logs_history(client, auth_headers, a_farm):
    create_resp = client.post("/crops", json={"name": "Tea", "farm_id": a_farm["id"]}, headers=auth_headers)
    crop_id = create_resp.json()["id"]

    client.put(f"/crops/{crop_id}", json={"status": "planted"}, headers=auth_headers)
    detail = client.get(f"/crops/{crop_id}", headers=auth_headers)

    events = [h["event"] for h in detail.json()["history_entries"]]
    assert "created" in events
    assert "status_changed" in events


def test_delete_crop(client, auth_headers, a_farm):
    create_resp = client.post("/crops", json={"name": "Corn", "farm_id": a_farm["id"]}, headers=auth_headers)
    crop_id = create_resp.json()["id"]
    del_resp = client.delete(f"/crops/{crop_id}", headers=auth_headers)
    assert del_resp.status_code == 204
