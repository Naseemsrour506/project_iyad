from fastapi.testclient import TestClient

from app.main import app
from tests.helpers import (
    create_child,
    register_and_login
)


client = TestClient(app)


def test_create_child_uses_logged_in_parent():
    headers, user_id = register_and_login(
        client,
        "create-child"
    )

    response = client.post(
        "/api/children",
        headers=headers,
        json={
            "full_name": "Ahmad",
            "age": 13
        }
    )

    assert response.status_code == 201

    data = response.json()

    assert data["parent_id"] == user_id
    assert data["full_name"] == "Ahmad"
    assert data["age"] == 13


def test_get_children_returns_only_current_users_children():
    first_headers, first_user_id = register_and_login(
        client,
        "first-parent"
    )

    second_headers, second_user_id = register_and_login(
        client,
        "second-parent"
    )

    create_child(
        client,
        first_headers,
        full_name="First Child"
    )

    create_child(
        client,
        second_headers,
        full_name="Second Child"
    )

    response = client.get(
        "/api/children",
        headers=first_headers
    )

    assert response.status_code == 200

    data = response.json()

    assert len(data) >= 1
    assert all(
        child["parent_id"] == first_user_id
        for child in data
    )

    assert all(
        child["parent_id"] != second_user_id
        for child in data
    )


def test_get_single_child():
    headers, _ = register_and_login(
        client,
        "single-child"
    )

    child_id = create_child(
        client,
        headers
    )

    response = client.get(
        f"/api/children/{child_id}",
        headers=headers
    )

    assert response.status_code == 200
    assert response.json()["child_id"] == child_id


def test_parent_cannot_access_another_parents_child():
    first_headers, _ = register_and_login(
        client,
        "child-owner"
    )

    second_headers, _ = register_and_login(
        client,
        "other-parent"
    )

    child_id = create_child(
        client,
        first_headers
    )

    response = client.get(
        f"/api/children/{child_id}",
        headers=second_headers
    )

    assert response.status_code == 404


def test_invalid_child_age_is_rejected():
    headers, _ = register_and_login(
        client,
        "invalid-age"
    )

    response = client.post(
        "/api/children",
        headers=headers,
        json={
            "full_name": "Invalid Child",
            "age": 25
        }
    )

    assert response.status_code == 422


def test_children_endpoint_requires_token():
    response = client.get("/api/children")

    assert response.status_code in (401, 403)
