from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def create_test_child(parent_id: int = 1) -> int:
    response = client.post(
        "/api/children",
        json={
            "parent_id": parent_id,
            "full_name": "Test Child",
            "age": 13
        }
    )

    assert response.status_code == 201
    return response.json()["child_id"]


def test_health_endpoint():
    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_analyze_bullying_message():
    child_id = create_test_child(parent_id=101)

    response = client.post(
        "/api/analyze",
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
    assert data["confidence"] == 0.88
    assert isinstance(data["message_id"], int)
    assert data["message_id"] > 0


def test_analyze_normal_message():
    child_id = create_test_child(parent_id=102)

    response = client.post(
        "/api/analyze",
        json={
            "child_id": child_id,
            "message": "שלום, מה שלומך?"
        }
    )

    assert response.status_code == 200

    data = response.json()

    assert data["category"] == "Normal"
    assert data["risk_level"] == "Low"


def test_missing_child_is_rejected():
    response = client.post(
        "/api/analyze",
        json={
            "child_id": 999999999,
            "message": "שלום"
        }
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Child not found"


def test_empty_message_is_rejected():
    response = client.post(
        "/api/analyze",
        json={
            "child_id": 1,
            "message": ""
        }
    )

    assert response.status_code == 422


def test_invalid_child_id_is_rejected():
    response = client.post(
        "/api/analyze",
        json={
            "child_id": 0,
            "message": "שלום"
        }
    )

    assert response.status_code == 422
