from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_create_child():
    response = client.post(
        "/api/children",
        json={
            "parent_id": 301,
            "full_name": "New Child",
            "age": 12
        }
    )

    assert response.status_code == 201

    data = response.json()

    assert isinstance(data["child_id"], int)
    assert data["parent_id"] == 301
    assert data["full_name"] == "New Child"
    assert data["age"] == 12
    assert "created_at" in data


def test_get_children_by_parent():
    client.post(
        "/api/children",
        json={
            "parent_id": 302,
            "full_name": "Parent Child",
            "age": 15
        }
    )

    response = client.get("/api/children?parent_id=302")

    assert response.status_code == 200

    data = response.json()

    assert isinstance(data, list)
    assert len(data) >= 1
    assert all(
        child["parent_id"] == 302
        for child in data
    )


def test_get_single_child():
    create_response = client.post(
        "/api/children",
        json={
            "parent_id": 303,
            "full_name": "Single Child",
            "age": 10
        }
    )

    child_id = create_response.json()["child_id"]

    response = client.get(f"/api/children/{child_id}")

    assert response.status_code == 200
    assert response.json()["child_id"] == child_id


def test_invalid_child_age_is_rejected():
    response = client.post(
        "/api/children",
        json={
            "parent_id": 304,
            "full_name": "Invalid Child",
            "age": 25
        }
    )

    assert response.status_code == 422
