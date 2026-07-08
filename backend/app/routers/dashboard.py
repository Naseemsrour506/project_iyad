from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies.auth import get_current_user
from app.models.child import Child
from app.models.message import Message
from app.models.prediction import Prediction
from app.models.user import User
from app.schemas.dashboard import DashboardStatsResponse


router = APIRouter(
    prefix="/api/dashboard",
    tags=["Dashboard"]
)


@router.get(
    "/stats",
    response_model=DashboardStatsResponse
)
def get_dashboard_stats(
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    total_children = (
        database_session
        .query(Child)
        .filter(Child.parent_id == current_user.id)
        .count()
    )

    total_messages = (
        database_session
        .query(Message)
        .join(
            Child,
            Message.child_id == Child.id
        )
        .filter(
            Child.parent_id == current_user.id
        )
        .count()
    )

    risk_rows = (
        database_session
        .query(
            Prediction.risk_level,
            func.count(Prediction.id)
        )
        .join(
            Message,
            Prediction.message_id == Message.id
        )
        .join(
            Child,
            Message.child_id == Child.id
        )
        .filter(
            Child.parent_id == current_user.id
        )
        .group_by(Prediction.risk_level)
        .all()
    )

    category_rows = (
        database_session
        .query(
            Prediction.category,
            func.count(Prediction.id)
        )
        .join(
            Message,
            Prediction.message_id == Message.id
        )
        .join(
            Child,
            Message.child_id == Child.id
        )
        .filter(
            Child.parent_id == current_user.id
        )
        .group_by(Prediction.category)
        .all()
    )

    risk_levels = {
        "Low": 0,
        "Medium": 0,
        "High": 0
    }

    for risk_level, count in risk_rows:
        risk_levels[risk_level] = count

    categories = {
        "Normal": 0,
        "Insult": 0,
        "Threat": 0,
        "Harassment": 0,
        "Bullying": 0
    }

    for category, count in category_rows:
        categories[category] = count

    return DashboardStatsResponse(
        total_children=total_children,
        total_messages=total_messages,
        risk_levels=risk_levels,
        categories=categories
    )
