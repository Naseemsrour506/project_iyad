from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Query,
    status
)
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies.auth import get_current_user
from app.models.alert import Alert
from app.models.child import Child
from app.models.user import User
from app.schemas.alert import (
    AlertResponse,
    UnreadAlertsCountResponse
)


router = APIRouter(
    prefix="/api/alerts",
    tags=["Alerts"]
)


def build_alert_response(alert: Alert) -> AlertResponse:
    return AlertResponse(
        alert_id=alert.id,
        child_id=alert.child_id,
        message_id=alert.message_id,
        title=alert.title,
        category=alert.category,
        risk_level=alert.risk_level,
        is_read=alert.is_read,
        created_at=alert.created_at
    )


def get_current_user_alerts_query(
    database_session: Session,
    current_user: User
):
    return (
        database_session
        .query(Alert)
        .join(
            Child,
            Alert.child_id == Child.id
        )
        .filter(
            Child.parent_id == current_user.id
        )
    )


@router.get(
    "",
    response_model=list[AlertResponse]
)
def get_alerts(
    unread_only: bool = Query(default=False),
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    query = get_current_user_alerts_query(
        database_session,
        current_user
    )

    if unread_only:
        query = query.filter(
            Alert.is_read.is_(False)
        )

    alerts = (
        query
        .order_by(Alert.created_at.desc())
        .all()
    )

    return [
        build_alert_response(alert)
        for alert in alerts
    ]


@router.get(
    "/unread-count",
    response_model=UnreadAlertsCountResponse
)
def get_unread_alerts_count(
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    unread_count = (
        get_current_user_alerts_query(
            database_session,
            current_user
        )
        .filter(
            Alert.is_read.is_(False)
        )
        .count()
    )

    return UnreadAlertsCountResponse(
        unread_count=unread_count
    )


@router.patch(
    "/{alert_id}/read",
    response_model=AlertResponse
)
def mark_alert_as_read(
    alert_id: int,
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    alert = (
        get_current_user_alerts_query(
            database_session,
            current_user
        )
        .filter(
            Alert.id == alert_id
        )
        .first()
    )

    if alert is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert not found"
        )

    alert.is_read = True

    database_session.commit()
    database_session.refresh(alert)

    return build_alert_response(alert)
