import csv
from io import StringIO
from typing import Optional

from fastapi import APIRouter, Depends, Query
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies.auth import get_current_user
from app.models.alert import Alert
from app.models.child import Child
from app.models.message import Message
from app.models.prediction import Prediction
from app.models.user import User
from app.schemas.report import (
    ChildReportSummary,
    ReportMessageResponse,
    ReportSummaryResponse
)


router = APIRouter(
    prefix="/api/reports",
    tags=["Reports"]
)


def get_current_user_report_query(
    database_session: Session,
    current_user: User
):
    return (
        database_session
        .query(Message, Prediction, Child)
        .join(
            Prediction,
            Prediction.message_id == Message.id
        )
        .join(
            Child,
            Message.child_id == Child.id
        )
        .filter(
            Child.parent_id == current_user.id
        )
    )


def apply_report_filters(
    query,
    child_id: Optional[int],
    category: Optional[str],
    risk_level: Optional[str]
):
    if child_id is not None:
        query = query.filter(
            Child.id == child_id
        )

    if category is not None:
        query = query.filter(
            Prediction.category == category
        )

    if risk_level is not None:
        query = query.filter(
            Prediction.risk_level == risk_level
        )

    return query


def build_report_message_response(
    message: Message,
    prediction: Prediction,
    child: Child
) -> ReportMessageResponse:
    return ReportMessageResponse(
        message_id=message.id,
        child_id=child.id,
        child_name=child.full_name,
        message=message.message_text,
        category=prediction.category,
        risk_level=prediction.risk_level,
        confidence=prediction.confidence,
        explanation=prediction.explanation,
        created_at=message.created_at
    )


@router.get(
    "/messages",
    response_model=list[ReportMessageResponse]
)
def get_report_messages(
    child_id: Optional[int] = Query(
        default=None,
        ge=1
    ),
    category: Optional[str] = Query(
        default=None
    ),
    risk_level: Optional[str] = Query(
        default=None
    ),
    limit: int = Query(
        default=100,
        ge=1,
        le=500
    ),
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    query = get_current_user_report_query(
        database_session,
        current_user
    )

    query = apply_report_filters(
        query,
        child_id,
        category,
        risk_level
    )

    rows = (
        query
        .order_by(Message.created_at.desc())
        .limit(limit)
        .all()
    )

    return [
        build_report_message_response(
            message,
            prediction,
            child
        )
        for message, prediction, child in rows
    ]


@router.get("/export")
def export_report_messages(
    child_id: Optional[int] = Query(
        default=None,
        ge=1
    ),
    category: Optional[str] = Query(
        default=None
    ),
    risk_level: Optional[str] = Query(
        default=None
    ),
    limit: int = Query(
        default=500,
        ge=1,
        le=1000
    ),
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    query = get_current_user_report_query(
        database_session,
        current_user
    )

    query = apply_report_filters(
        query,
        child_id,
        category,
        risk_level
    )

    rows = (
        query
        .order_by(Message.created_at.desc())
        .limit(limit)
        .all()
    )

    csv_file = StringIO()
    csv_file.write("\ufeff")

    writer = csv.writer(csv_file)

    writer.writerow([
        "message_id",
        "child_id",
        "child_name",
        "message",
        "category",
        "risk_level",
        "confidence",
        "explanation",
        "created_at"
    ])

    for message, prediction, child in rows:
        writer.writerow([
            message.id,
            child.id,
            child.full_name,
            message.message_text,
            prediction.category,
            prediction.risk_level,
            prediction.confidence,
            prediction.explanation,
            message.created_at.isoformat()
        ])

    return Response(
        content=csv_file.getvalue(),
        media_type="text/csv; charset=utf-8",
        headers={
            "Content-Disposition": (
                'attachment; filename="safechat_report.csv"'
            )
        }
    )


@router.get(
    "/summary",
    response_model=ReportSummaryResponse
)
def get_report_summary(
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    children = (
        database_session
        .query(Child)
        .filter(
            Child.parent_id == current_user.id
        )
        .order_by(Child.created_at.desc())
        .all()
    )

    child_summary_map = {
        child.id: {
            "child_id": child.id,
            "child_name": child.full_name,
            "total_messages": 0,
            "high_risk_messages": 0
        }
        for child in children
    }

    messages_by_risk_level = {
        "Low": 0,
        "Medium": 0,
        "High": 0
    }

    messages_by_category = {
        "Normal": 0,
        "Insult": 0,
        "Threat": 0,
        "Harassment": 0,
        "Bullying": 0
    }

    rows = (
        get_current_user_report_query(
            database_session,
            current_user
        )
        .all()
    )

    total_messages = 0
    high_risk_messages = 0

    for message, prediction, child in rows:
        total_messages += 1

        messages_by_risk_level[prediction.risk_level] = (
            messages_by_risk_level.get(
                prediction.risk_level,
                0
            )
            + 1
        )

        messages_by_category[prediction.category] = (
            messages_by_category.get(
                prediction.category,
                0
            )
            + 1
        )

        if child.id in child_summary_map:
            child_summary_map[child.id]["total_messages"] += 1

        if prediction.risk_level == "High":
            high_risk_messages += 1

            if child.id in child_summary_map:
                child_summary_map[child.id]["high_risk_messages"] += 1

    unread_alerts = (
        database_session
        .query(Alert)
        .join(
            Child,
            Alert.child_id == Child.id
        )
        .filter(
            Child.parent_id == current_user.id,
            Alert.is_read.is_(False)
        )
        .count()
    )

    return ReportSummaryResponse(
        total_children=len(children),
        total_messages=total_messages,
        high_risk_messages=high_risk_messages,
        unread_alerts=unread_alerts,
        messages_by_risk_level=messages_by_risk_level,
        messages_by_category=messages_by_category,
        messages_by_child=[
            ChildReportSummary(**child_summary)
            for child_summary in child_summary_map.values()
        ]
    )
