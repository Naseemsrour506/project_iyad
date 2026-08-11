from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies.auth import get_current_user
from app.models.child import Child
from app.models.message import Message
from app.models.user import User
from app.schemas.message import MessageResponse


router = APIRouter(
    prefix="/api/messages",
    tags=["Messages"]
)


@router.get(
    "",
    response_model=list[MessageResponse]
)
def get_messages(
    child_id: Optional[int] = Query(
        default=None,
        ge=1
    ),
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    query = (
        database_session
        .query(Message)
        .join(
            Child,
            Message.child_id == Child.id
        )
        .filter(
            Child.parent_id == current_user.id
        )
    )

    if child_id is not None:
        query = query.filter(
            Message.child_id == child_id
        )

    message_records = (
        query
        .order_by(Message.created_at.desc())
        .all()
    )

    return [
        MessageResponse(
            message_id=message_record.id,
            child_id=message_record.child_id,
            message=message_record.message_text,
            category=message_record.prediction.category,
            risk_level=message_record.prediction.risk_level,
            confidence=message_record.prediction.confidence,
            explanation=message_record.prediction.explanation,
            created_at=message_record.created_at
        )
        for message_record in message_records
        if message_record.prediction is not None
    ]
