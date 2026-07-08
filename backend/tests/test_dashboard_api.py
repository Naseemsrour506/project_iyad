from fastapi.testclient import TestClient

from app.main import app
from tests.helpers import (
    create_child,
    register_and_login
)


client = TestClient(app)


def test_dashboard_stats():
    headers, _ = register_and_login(
        client,
        "dashboard-stats"
    )

    child_id = create_child(
        client,
        headers,
        full_name="Dashboard Child"
    )

    normal_response = client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": child_id,
            "message": "שלום, מה שלומך?"
        }
    )

    bullying_response = client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": child_id,
            "message": "אף אחד לא אוהב אותך"
        }
    )

    assert normal_response.status_code == 200
    assert bullying_response.status_code == 200

    response = client.get(
        "/api/dashboard/stats",
        headers=headers
    )

    assert response.status_code == 200

    data = response.json()

    assert data["total_children"] == 1
    assert data["total_messages"] == 2

    assert data["risk_levels"]["Low"] == 1
    assert data["risk_levels"]["High"] == 1

    assert data["categories"]["Normal"] == 1
    assert data["categories"]["Bullying"] == 1


def test_dashboard_contains_only_current_users_data():
    first_headers, _ = register_and_login(
        client,
        "dashboard-first"
    )

    second_headers, _ = register_and_login(
        client,
        "dashboard-second"
    )

    first_child_id = create_child(
        client,
        first_headers
    )

    client.post(
        "/api/analyze",
        headers=first_headers,
        json={
            "child_id": first_child_id,
            "message": "אתה אפס ואף אחד לא אוהב אותך"
        }
    )

    response = client.get(
        "/api/dashboard/stats",
        headers=second_headers
    )

    assert response.status_code == 200

    data = response.json()

    assert data["total_children"] == 0
    assert data["total_messages"] == 0
    assert sum(data["risk_levels"].values()) == 0
    assert sum(data["categories"].values()) == 0


def test_dashboard_requires_authentication():
    response = client.get(
        "/api/dashboard/stats"
    )

    assert response.status_code in (401, 403)
