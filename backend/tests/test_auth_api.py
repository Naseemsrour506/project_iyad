from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def create_unique_email(prefix: str) -> str:
    return (
        f"{prefix}-{uuid4().hex}"
        "@example.com"
    )


def test_register_user():
    email = create_unique_email("register")

    response = client.post(
        "/api/auth/register",
        json={
            "full_name": "Test Parent",
            "email": email,
            "password": "StrongPassword123"
        }
    )

    assert response.status_code == 201

    data = response.json()

    assert data["email"] == email
    assert data["role"] == "Parent"
    assert isinstance(data["user_id"], int)
    assert "password" not in data
    assert "password_hash" not in data


def test_duplicate_email_is_rejected():
    email = create_unique_email("duplicate")

    request_body = {
        "full_name": "Duplicate Parent",
        "email": email,
        "password": "StrongPassword123"
    }

    first_response = client.post(
        "/api/auth/register",
        json=request_body
    )

    second_response = client.post(
        "/api/auth/register",
        json=request_body
    )

    assert first_response.status_code == 201
    assert second_response.status_code == 409


def test_login_returns_access_token():
    email = create_unique_email("login")
    password = "StrongPassword123"

    client.post(
        "/api/auth/register",
        json={
            "full_name": "Login Parent",
            "email": email,
            "password": password
        }
    )

    response = client.post(
        "/api/auth/login",
        json={
            "email": email,
            "password": password
        }
    )

    assert response.status_code == 200

    data = response.json()

    assert isinstance(data["access_token"], str)
    assert len(data["access_token"]) > 20
    assert data["token_type"] == "bearer"
    assert data["user"]["email"] == email


def test_wrong_password_is_rejected():
    email = create_unique_email("wrong-password")

    client.post(
        "/api/auth/register",
        json={
            "full_name": "Password Parent",
            "email": email,
            "password": "CorrectPassword123"
        }
    )

    response = client.post(
        "/api/auth/login",
        json={
            "email": email,
            "password": "WrongPassword123"
        }
    )

    assert response.status_code == 401


def test_get_current_user():
    email = create_unique_email("current-user")
    password = "StrongPassword123"

    client.post(
        "/api/auth/register",
        json={
            "full_name": "Current Parent",
            "email": email,
            "password": password
        }
    )

    login_response = client.post(
        "/api/auth/login",
        json={
            "email": email,
            "password": password
        }
    )

    token = login_response.json()["access_token"]

    response = client.get(
        "/api/auth/me",
        headers={
            "Authorization": f"Bearer {token}"
        }
    )

    assert response.status_code == 200
    assert response.json()["email"] == email


def test_get_current_user_without_token_is_rejected():
    response = client.get("/api/auth/me")

    assert response.status_code in (401, 403)
