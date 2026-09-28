def test_create_farm(client, auth_headers):
    resp = client.post("/farms", json={
        "name": "Green Valley Farm",
        "district": "Kandy",
        "size_acres": 2.5,
        "water_availability": "moderate",
    }, headers=auth_headers)
    assert resp.status_code == 201
    assert resp.json()["name"] == "Green Valley Farm"


def test_create_farm_requires_auth(client):
    resp = client.post("/farms", json={"name": "No Auth Farm"})
    assert resp.status_code == 401


def test_list_farms_only_shows_own(client, auth_headers):
    client.post("/farms", json={"name": "Farm A"}, headers=auth_headers)
    client.post("/farms", json={"name": "Farm B"}, headers=auth_headers)
    resp = client.get("/farms", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 2


def test_update_farm(client, auth_headers):
    create_resp = client.post("/farms", json={"name": "Old Name"}, headers=auth_headers)
    farm_id = create_resp.json()["id"]
    resp = client.put(f"/farms/{farm_id}", json={"name": "New Name"}, headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["name"] == "New Name"


def test_delete_farm(client, auth_headers):
    create_resp = client.post("/farms", json={"name": "To Delete"}, headers=auth_headers)
    farm_id = create_resp.json()["id"]
    del_resp = client.delete(f"/farms/{farm_id}", headers=auth_headers)
    assert del_resp.status_code == 204
    get_resp = client.get(f"/farms/{farm_id}", headers=auth_headers)
    assert get_resp.status_code == 404
