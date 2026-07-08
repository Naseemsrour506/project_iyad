from fastapi.testclient import TestClient

from app.main import app
from tests.helpers import (
    create_child,
    register_and_login
)


client = TestClient(app)


def test_health_endpoint():
    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_analyze_bullying_message():
    headers, _ = register_and_login(
        client,
        "analyze-bullying"
    )

    child_id = create_child(
        client,
        headers
    )

    response = client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": child_id,
            "message": "אתה אפס ואף אחד לא אוהב אותך"
        }
    )

    assert response.status_code == 200

    data = response.json()

    assert data["child_id"] == child_id
    assert data["category"] == "Bullying"
    assert data["risk_level"] == "High"
    assert isinstance(data["message_id"], int)


def test_analyze_normal_message():
    headers, _ = register_and_login(
        client,
        "analyze-normal"
    )

    child_id = create_child(
        client,
        headers
    )

    response = client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": child_id,
            "message": "שלום, מה שלומך?"
        }
    )

    assert response.status_code == 200
    assert response.json()["category"] == "Normal"


def test_parent_cannot_analyze_another_parents_child():
    owner_headers, _ = register_and_login(
        client,
        "analyze-owner"
    )

    other_headers, _ = register_and_login(
        client,
        "analyze-other"
    )

    child_id = create_child(
        client,
        owner_headers
    )

    response = client.post(
        "/api/analyze",
        headers=other_headers,
        json={
            "child_id": child_id,
            "message": "שלום"
        }
    )

    assert response.status_code == 404


def test_missing_child_is_rejected():
    headers, _ = register_and_login(
        client,
        "missing-child"
    )

    response = client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": 999999999,
            "message": "שלום"
        }
    )

    assert response.status_code == 404


def test_empty_message_is_rejected():
    headers, _ = register_and_login(
        client,
        "empty-message"
    )

    response = client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": 1,
            "message": ""
        }
    )

    assert response.status_code == 422


def test_analyze_endpoint_requires_token():
    response = client.post(
        "/api/analyze",
        json={
            "child_id": 1,
            "message": "שלום"
        }
    )

    assert response.status_code in (401, 403)
