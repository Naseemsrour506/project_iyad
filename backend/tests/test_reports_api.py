from fastapi.testclient import TestClient

from app.main import app
from tests.helpers import (
    create_child,
    register_and_login
)


client = TestClient(app)


def test_get_report_messages():
    headers, _ = register_and_login(
        client,
        "report-messages"
    )

    child_id = create_child(
        client,
        headers,
        full_name="Report Child"
    )

    client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": child_id,
            "message": "שלום, מה שלומך?"
        }
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
        "/api/reports/messages",
        headers=headers
    )

    assert response.status_code == 200

    data = response.json()

    assert len(data) == 2
    assert all(
        message["child_id"] == child_id
        for message in data
    )
    assert all(
        message["child_name"] == "Report Child"
        for message in data
    )


def test_report_messages_filter_by_risk_level():
    headers, _ = register_and_login(
        client,
        "report-risk"
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

    client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": child_id,
            "message": "אתה אפס ואף אחד לא אוהב אותך"
        }
    )

    response = client.get(
        "/api/reports/messages?risk_level=High",
        headers=headers
    )

    assert response.status_code == 200

    data = response.json()

    assert len(data) == 1
    assert data[0]["risk_level"] == "High"
    assert data[0]["category"] == "Bullying"


def test_report_messages_filter_by_category():
    headers, _ = register_and_login(
        client,
        "report-category"
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
        "/api/reports/messages?category=Bullying",
        headers=headers
    )

    assert response.status_code == 200

    data = response.json()

    assert len(data) == 1
    assert data[0]["category"] == "Bullying"
    assert data[0]["risk_level"] == "High"


def test_report_summary():
    headers, _ = register_and_login(
        client,
        "report-summary"
    )

    child_id = create_child(
        client,
        headers,
        full_name="Summary Child"
    )

    client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": child_id,
            "message": "שלום, מה שלומך?"
        }
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
        "/api/reports/summary",
        headers=headers
    )

    assert response.status_code == 200

    data = response.json()

    assert data["total_children"] == 1
    assert data["total_messages"] == 2
    assert data["high_risk_messages"] == 1
    assert data["unread_alerts"] == 1

    assert data["messages_by_risk_level"]["Low"] == 1
    assert data["messages_by_risk_level"]["High"] == 1

    assert data["messages_by_category"]["Normal"] == 1
    assert data["messages_by_category"]["Bullying"] == 1

    assert len(data["messages_by_child"]) == 1
    assert data["messages_by_child"][0]["child_name"] == "Summary Child"
    assert data["messages_by_child"][0]["total_messages"] == 2
    assert data["messages_by_child"][0]["high_risk_messages"] == 1


def test_reports_contain_only_current_users_data():
    owner_headers, _ = register_and_login(
        client,
        "report-owner"
    )

    other_headers, _ = register_and_login(
        client,
        "report-other"
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

    messages_response = client.get(
        "/api/reports/messages",
        headers=other_headers
    )

    summary_response = client.get(
        "/api/reports/summary",
        headers=other_headers
    )

    assert messages_response.status_code == 200
    assert messages_response.json() == []

    assert summary_response.status_code == 200
    assert summary_response.json()["total_children"] == 0
    assert summary_response.json()["total_messages"] == 0
    assert summary_response.json()["high_risk_messages"] == 0


def test_reports_require_authentication():
    messages_response = client.get(
        "/api/reports/messages"
    )

    summary_response = client.get(
        "/api/reports/summary"
    )

    assert messages_response.status_code in (401, 403)
    assert summary_response.status_code in (401, 403)


def test_export_report_messages_as_csv():
    headers, _ = register_and_login(
        client,
        "report-export"
    )

    child_id = create_child(
        client,
        headers,
        full_name="Export Child"
    )

    client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": child_id,
            "message": "שלום מה שלומך?"
        }
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
        "/api/reports/export",
        headers=headers
    )

    assert response.status_code == 200
    assert "text/csv" in response.headers["content-type"]
    assert (
        response.headers["content-disposition"]
        == 'attachment; filename="safechat_report.csv"'
    )

    csv_text = response.text

    assert "message_id,child_id,child_name,message,category,risk_level" in csv_text
    assert "Export Child" in csv_text
    assert "Normal" in csv_text
    assert "Bullying" in csv_text
    assert "High" in csv_text


def test_export_report_messages_filter_by_risk_level():
    headers, _ = register_and_login(
        client,
        "report-export-risk"
    )

    child_id = create_child(
        client,
        headers,
        full_name="Export Risk Child"
    )

    client.post(
        "/api/analyze",
        headers=headers,
        json={
            "child_id": child_id,
            "message": "שלום"
        }
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
        "/api/reports/export?risk_level=High",
        headers=headers
    )

    assert response.status_code == 200

    csv_text = response.text

    assert "Bullying" in csv_text
    assert "High" in csv_text
    assert "Normal" not in csv_text


def test_export_report_messages_requires_authentication():
    response = client.get(
        "/api/reports/export"
    )

    assert response.status_code in (401, 403)
