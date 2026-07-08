from uuid import uuid4

from fastapi.testclient import TestClient


def register_and_login(
    client: TestClient,
    prefix: str = "parent"
) -> tuple[dict[str, str], int]:
    email = (
        f"{prefix}-{uuid4().hex}"
        "@example.com"
    )

    password = "StrongPassword123"

    register_response = client.post(
        "/api/auth/register",
        json={
            "full_name": "Test Parent",
            "email": email,
            "password": password
        }
    )

    assert register_response.status_code == 201

    user_id = register_response.json()["user_id"]

    login_response = client.post(
        "/api/auth/login",
        json={
            "email": email,
            "password": password
        }
    )

    assert login_response.status_code == 200

    token = login_response.json()["access_token"]

    headers = {
        "Authorization": f"Bearer {token}"
    }

    return headers, user_id


def create_child(
    client: TestClient,
    headers: dict[str, str],
    full_name: str = "Test Child",
    age: int = 13
) -> int:
    response = client.post(
        "/api/children",
        headers=headers,
        json={
            "full_name": full_name,
            "age": age
        }
    )

    assert response.status_code == 201

    return response.json()["child_id"]
