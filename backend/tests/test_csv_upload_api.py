from fastapi.testclient import TestClient

from app.main import app
from tests.helpers import (
    create_child,
    register_and_login
)


client = TestClient(app)


def test_upload_messages_csv():
    headers, _ = register_and_login(
        client,
        "csv-upload"
    )

    child_id = create_child(
        client,
        headers,
        full_name="CSV Child"
    )

    csv_content = (
        "message\n"
        "שלום מה שלומך\n"
        "אתה אפס ואף אחד לא אוהב אותך\n"
        "אני מקווה שיהיה לך יום טוב\n"
    )

    response = client.post(
        "/api/messages/upload",
        headers=headers,
        data={
            "child_id": str(child_id)
        },
        files={
            "file": (
                "messages.csv",
                csv_content.encode("utf-8"),
                "text/csv"
            )
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

    assert "Low" in risk_levels
    assert "High" in risk_levels


def test_upload_messages_csv_saves_messages_to_history():
    headers, _ = register_and_login(
        client,
        "csv-history"
    )

    child_id = create_child(
        client,
        headers
    )

    csv_content = (
        "message\n"
        "שלום\n"
        "אתה אפס ואף אחד לא אוהב אותך\n"
    )

    response = client.post(
        "/api/messages/upload",
        headers=headers,
        data={
            "child_id": str(child_id)
        },
        files={
            "file": (
                "messages.csv",
                csv_content.encode("utf-8"),
                "text/csv"
            )
        }
    )

    assert response.status_code == 200

    messages_response = client.get(
        "/api/messages",
        headers=headers
    )

    assert messages_response.status_code == 200
    assert len(messages_response.json()) == 2


def test_upload_messages_csv_creates_alert_for_high_risk_message():
    headers, _ = register_and_login(
        client,
        "csv-alert"
    )

    child_id = create_child(
        client,
        headers
    )

    csv_content = (
        "message\n"
        "אתה אפס ואף אחד לא אוהב אותך\n"
    )

    response = client.post(
        "/api/messages/upload",
        headers=headers,
        data={
            "child_id": str(child_id)
        },
        files={
            "file": (
                "messages.csv",
                csv_content.encode("utf-8"),
                "text/csv"
            )
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


def test_upload_messages_csv_rejects_missing_message_column():
    headers, _ = register_and_login(
        client,
        "csv-no-message-column"
    )

    child_id = create_child(
        client,
        headers
    )

    csv_content = (
        "text\n"
        "שלום\n"
    )

    response = client.post(
        "/api/messages/upload",
        headers=headers,
        data={
            "child_id": str(child_id)
        },
        files={
            "file": (
                "messages.csv",
                csv_content.encode("utf-8"),
                "text/csv"
            )
        }
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "CSV file must contain a message column"
    )


def test_upload_messages_csv_rejects_empty_csv():
    headers, _ = register_and_login(
        client,
        "csv-empty"
    )

    child_id = create_child(
        client,
        headers
    )

    response = client.post(
        "/api/messages/upload",
        headers=headers,
        data={
            "child_id": str(child_id)
        },
        files={
            "file": (
                "messages.csv",
                b"",
                "text/csv"
            )
        }
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "CSV file is empty"


def test_upload_messages_csv_rejects_other_parent_child():
    owner_headers, _ = register_and_login(
        client,
        "csv-owner"
    )

    other_headers, _ = register_and_login(
        client,
        "csv-other"
    )

    owner_child_id = create_child(
        client,
        owner_headers
    )

    csv_content = (
        "message\n"
        "שלום\n"
    )

    response = client.post(
        "/api/messages/upload",
        headers=other_headers,
        data={
            "child_id": str(owner_child_id)
        },
        files={
            "file": (
                "messages.csv",
                csv_content.encode("utf-8"),
                "text/csv"
            )
        }
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Child not found"


def test_upload_messages_csv_requires_authentication():
    csv_content = (
        "message\n"
        "שלום\n"
    )

    response = client.post(
        "/api/messages/upload",
        data={
            "child_id": "1"
        },
        files={
            "file": (
                "messages.csv",
                csv_content.encode("utf-8"),
                "text/csv"
            )
        }
    )

    assert response.status_code in (401, 403)
