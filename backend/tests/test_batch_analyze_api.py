from fastapi.testclient import TestClient

from app.main import app
from tests.helpers import (
    create_child,
    register_and_login
)


client = TestClient(app)


def test_batch_analyze_messages():
    headers, _ = register_and_login(
        client,
        "batch-parent"
    )

    child_id = create_child(
        client,
        headers,
        full_name="Batch Child"
    )

    response = client.post(
        "/api/analyze/batch",
        headers=headers,
        json={
            "child_id": child_id,
            "messages": [
                "שלום מה שלומך",
                "אתה אפס ואף אחד לא אוהב אותך",
                "אני מקווה שיהיה לך יום טוב"
            ]
        }
    )

    assert response.status_code == 200

    data = response.json()

    assert data["child_id"] == child_id
    assert data["total_messages"] == 3
    assert len(data["results"]) == 3

    risk_levels = [
        result["risk_level"]
        for result in data["results"]
    ]

    assert "High" in risk_levels
    assert "Low" in risk_levels


def test_batch_analyze_creates_alert_for_high_risk_message():
    headers, _ = register_and_login(
        client,
        "batch-alert"
    )

    child_id = create_child(
        client,
        headers
    )

    response = client.post(
        "/api/analyze/batch",
        headers=headers,
        json={
            "child_id": child_id,
            "messages": [
                "אתה אפס ואף אחד לא אוהב אותך"
            ]
        }
    )

    assert response.status_code == 200

    alerts_response = client.get(
        "/api/alerts",
        headers=headers
    )

    assert alerts_response.status_code == 200

    alerts = alerts_response.json()

    assert len(alerts) == 1
    assert alerts[0]["risk_level"] == "High"
    assert alerts[0]["category"] == "Bullying"


def test_batch_analyze_saves_messages_to_history():
    headers, _ = register_and_login(
        client,
        "batch-history"
    )

    child_id = create_child(
        client,
        headers
    )

    response = client.post(
        "/api/analyze/batch",
        headers=headers,
        json={
            "child_id": child_id,
            "messages": [
                "שלום",
                "אתה אפס ואף אחד לא אוהב אותך"
            ]
        }
    )

    assert response.status_code == 200

    messages_response = client.get(
        "/api/messages",
        headers=headers
    )

    assert messages_response.status_code == 200

    messages = messages_response.json()

    assert len(messages) == 2


def test_batch_analyze_rejects_empty_list():
    headers, _ = register_and_login(
        client,
        "batch-empty"
    )

    child_id = create_child(
        client,
        headers
    )

    response = client.post(
        "/api/analyze/batch",
        headers=headers,
        json={
            "child_id": child_id,
            "messages": []
        }
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Messages list cannot be empty"


def test_batch_analyze_rejects_empty_message_text():
    headers, _ = register_and_login(
        client,
        "batch-empty-message"
    )

    child_id = create_child(
        client,
        headers
    )

    response = client.post(
        "/api/analyze/batch",
        headers=headers,
        json={
            "child_id": child_id,
            "messages": [
                "שלום",
                ""
            ]
        }
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Message text cannot be empty"


def test_batch_analyze_rejects_other_parent_child():
    owner_headers, _ = register_and_login(
        client,
        "batch-owner"
    )

    other_headers, _ = register_and_login(
        client,
        "batch-other"
    )

    owner_child_id = create_child(
        client,
        owner_headers
    )

    response = client.post(
        "/api/analyze/batch",
        headers=other_headers,
        json={
            "child_id": owner_child_id,
            "messages": [
                "שלום"
            ]
        }
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Child not found"


def test_batch_analyze_requires_authentication():
    response = client.post(
        "/api/analyze/batch",
        json={
            "child_id": 1,
            "messages": [
                "שלום"
            ]
        }
    )

    assert response.status_code in (401, 403)
