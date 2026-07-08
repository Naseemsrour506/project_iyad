from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def create_test_child(parent_id: int) -> int:
    response = client.post(
        "/api/children",
        json={
            "parent_id": parent_id,
            "full_name": "Messages Test Child",
            "age": 14
        }
    )

    assert response.status_code == 201
    return response.json()["child_id"]


def test_get_messages_returns_list():
    child_id = create_test_child(parent_id=201)

    client.post(
        "/api/analyze",
        json={
            "child_id": child_id,
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
    child_id = create_test_child(parent_id=202)

    client.post(
        "/api/analyze",
        json={
            "child_id": child_id,
            "message": "אתה טיפש"
        }
    )

    response = client.get(
        f"/api/messages?child_id={child_id}"
    )

    assert response.status_code == 200

    data = response.json()

    assert isinstance(data, list)
    assert len(data) >= 1
    assert all(
        message["child_id"] == child_id
        for message in data
    )


def test_invalid_child_id_filter_is_rejected():
    response = client.get("/api/messages?child_id=0")

    assert response.status_code == 422
