from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_get_messages_returns_list():
    client.post(
        "/api/analyze",
        json={
            "child_id": 10,
            "message": "שלום, מה שלומך?"
        }
    )

    response = client.get("/api/messages")

    assert response.status_code == 200

    data = response.json()

    assert isinstance(data, list)
    assert len(data) >= 1

    message = data[0]

    assert "message_id" in message
    assert "child_id" in message
    assert "message" in message
    assert "category" in message
    assert "risk_level" in message
    assert "confidence" in message
    assert "created_at" in message


def test_get_messages_by_child_id():
    client.post(
        "/api/analyze",
        json={
            "child_id": 20,
            "message": "אתה טיפש"
        }
    )

    response = client.get("/api/messages?child_id=20")

    assert response.status_code == 200

    data = response.json()

    assert isinstance(data, list)
    assert len(data) >= 1
    assert all(message["child_id"] == 20 for message in data)


def test_invalid_child_id_filter_is_rejected():
    response = client.get("/api/messages?child_id=0")

    assert response.status_code == 422
