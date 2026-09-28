def test_register_creates_user_and_profile(client):
    resp = client.post("/users/register", json={
        "email": "newfarmer@example.com",
        "password": "securepass123",
        "full_name": "Kamala Silva",
        "role": "farmer",
    })
    assert resp.status_code == 201
    body = resp.json()
    assert body["email"] == "newfarmer@example.com"
    assert body["farmer_profile"]["full_name"] == "Kamala Silva"


def test_register_duplicate_email_rejected(client, registered_farmer):
    resp = client.post("/users/register", json={
        "email": registered_farmer["email"],
        "password": "anotherpass123",
        "full_name": "Someone Else",
    })
    assert resp.status_code == 400


def test_login_success(client, registered_farmer):
    resp = client.post("/users/login", json={
        "email": registered_farmer["email"],
        "password": registered_farmer["password"],
    })
    assert resp.status_code == 200
    assert "access_token" in resp.json()
    assert "refresh_token" in resp.json()


def test_login_wrong_password_rejected(client, registered_farmer):
    resp = client.post("/users/login", json={
        "email": registered_farmer["email"],
        "password": "wrong-password",
    })
    assert resp.status_code == 401


def test_get_me_requires_auth(client):
    resp = client.get("/users/me")
    assert resp.status_code == 401


def test_get_me_returns_profile(client, auth_headers):
    resp = client.get("/users/me", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["farmer_profile"]["full_name"] == "Nimal Perera"


def test_logout_revokes_token(client, auth_headers):
    resp = client.post("/users/logout", headers=auth_headers)
    assert resp.status_code == 204
