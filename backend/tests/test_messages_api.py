from fastapi.testclient import TestClient

from app.main import app
from tests.helpers import (
    create_child,
    register_and_login
)


client = TestClient(app)


def test_get_messages_returns_list():
    headers, _ = register_and_login(
        client,
        "messages-list"
    )

    child_id = create_child(
        client,
        headers
    )

    client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": child_id,
            "message": "שלום, מה שלומך?"
        }
    )

    response = client.get(
        "/api/messages",
        headers=headers
    )

    assert response.status_code == 200

    data = response.json()

    assert isinstance(data, list)
    assert len(data) >= 1


def test_get_messages_by_child_id():
    headers, _ = register_and_login(
        client,
        "messages-filter"
    )

    child_id = create_child(
        client,
        headers
    )

    client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": child_id,
            "message": "אתה טיפש"
        }
    )

    response = client.get(
        f"/api/messages?child_id={child_id}",
        headers=headers
    )

    assert response.status_code == 200

    data = response.json()

    assert len(data) >= 1
    assert all(
        message["child_id"] == child_id
        for message in data
    )


def test_parent_cannot_see_another_parents_messages():
    owner_headers, _ = register_and_login(
        client,
        "message-owner"
    )

    other_headers, _ = register_and_login(
        client,
        "message-other"
    )

    child_id = create_child(
        client,
        owner_headers
    )

    client.post(
        "/api/analyze",
        headers=owner_headers,
        json={
            "child_id": child_id,
            "message": "אתה טיפש"
        }
    )

    response = client.get(
        "/api/messages",
        headers=other_headers
    )

    assert response.status_code == 200

    data = response.json()

    assert all(
        message["child_id"] != child_id
        for message in data
    )


def test_invalid_child_filter_is_rejected():
    headers, _ = register_and_login(
        client,
        "invalid-filter"
    )

    response = client.get(
        "/api/messages?child_id=0",
        headers=headers
    )

    assert response.status_code == 422


def test_messages_endpoint_requires_token():
    response = client.get("/api/messages")

    assert response.status_code in (401, 403)
