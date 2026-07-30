from fastapi.testclient import TestClient

from app.main import app
from tests.helpers import (
    create_child,
    register_and_login
)


client = TestClient(app)


def test_high_risk_message_creates_alert():
    headers, _ = register_and_login(
        client,
        "alert-high-risk"
    )

    child_id = create_child(
        client,
        headers
    )

    analyze_response = client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": child_id,
            "message": "אתה אפס ואף אחד לא אוהב אותך"
        }
    )

    assert analyze_response.status_code == 200

    message_id = analyze_response.json()["message_id"]

    response = client.get(
        "/api/alerts",
        headers=headers
    )

    assert response.status_code == 200

    alerts = response.json()

    matching_alerts = [
        alert
        for alert in alerts
        if alert["message_id"] == message_id
    ]

    assert len(matching_alerts) == 1

    alert = matching_alerts[0]

    assert alert["child_id"] == child_id
    assert alert["risk_level"] == "High"
    assert alert["category"] == "Bullying"
    assert alert["is_read"] is False


def test_normal_message_does_not_create_alert():
    headers, _ = register_and_login(
        client,
        "alert-normal"
    )

    child_id = create_child(
        client,
        headers
    )

    analyze_response = client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": child_id,
            "message": "שלום, מה שלומך?"
        }
    )

    assert analyze_response.status_code == 200

    response = client.get(
        "/api/alerts",
        headers=headers
    )

    assert response.status_code == 200
    assert response.json() == []


def test_alerts_contain_only_current_users_data():
    owner_headers, _ = register_and_login(
        client,
        "alert-owner"
    )

    other_headers, _ = register_and_login(
        client,
        "alert-other"
    )

    owner_child_id = create_child(
        client,
        owner_headers
    )

    client.post(
        "/api/analyze",
        headers=owner_headers,
        json={
            "child_id": owner_child_id,
            "message": "אתה אפס ואף אחד לא אוהב אותך"
        }
    )

    response = client.get(
        "/api/alerts",
        headers=other_headers
    )

    assert response.status_code == 200
    assert response.json() == []


def test_mark_alert_as_read():
    headers, _ = register_and_login(
        client,
        "alert-read"
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
            "message": "אתה אפס ואף אחד לא אוהב אותך"
        }
    )

    alerts_response = client.get(
        "/api/alerts",
        headers=headers
    )

    assert alerts_response.status_code == 200

    alert_id = alerts_response.json()[0]["alert_id"]

    mark_read_response = client.patch(
        f"/api/alerts/{alert_id}/read",
        headers=headers
    )

    assert mark_read_response.status_code == 200
    assert mark_read_response.json()["is_read"] is True

    unread_response = client.get(
        "/api/alerts?unread_only=true",
        headers=headers
    )

    assert unread_response.status_code == 200
    assert unread_response.json() == []


def test_unread_alerts_count():
    headers, _ = register_and_login(
        client,
        "alert-count"
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
            "message": "אתה אפס ואף אחד לא אוהב אותך"
        }
    )

    response = client.get(
        "/api/alerts/unread-count",
        headers=headers
    )

    assert response.status_code == 200
    assert response.json()["unread_count"] == 1


def test_alerts_endpoint_requires_authentication():
    response = client.get("/api/alerts")

    assert response.status_code in (401, 403)
