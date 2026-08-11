from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status
)
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies.auth import get_current_user
from app.models.alert import Alert
from app.models.child import Child
from app.models.message import Message
from app.models.prediction import Prediction
from app.models.user import User
from app.schemas.analyze import (
    AnalyzeRequest,
    AnalyzeResponse,
    BatchAnalyzeRequest,
    BatchAnalyzeResponse
)
from app.services.classifier import analyze_message


router = APIRouter(
    prefix="/api",
    tags=["Message Analysis"]
)


def get_child_for_current_user(
    child_id: int,
    current_user: User,
    database_session: Session
) -> Child:
    child = (
        database_session
        .query(Child)
        .filter(
            Child.id == child_id,
            Child.parent_id == current_user.id
        )
        .first()
    )

    if child is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Child not found"
        )

    return child


def save_analyzed_message(
    child: Child,
    message_text: str,
    database_session: Session
) -> AnalyzeResponse:
    analysis_result = analyze_message(message_text)

    message_record = Message(
        child_id=child.id,
        message_text=message_text
    )

    database_session.add(message_record)
    database_session.flush()

    prediction_record = Prediction(
        message_id=message_record.id,
        category=analysis_result["category"],
        risk_level=analysis_result["risk_level"],
        confidence=analysis_result["confidence"],
        explanation=analysis_result["explanation"]
    )

    database_session.add(prediction_record)
    database_session.flush()

    if prediction_record.risk_level == "High":
        alert_record = Alert(
            child_id=child.id,
            message_id=message_record.id,
            prediction_id=prediction_record.id,
            title="High risk message detected",
            category=prediction_record.category,
            risk_level=prediction_record.risk_level
        )

        database_session.add(alert_record)

    return AnalyzeResponse(
        message_id=message_record.id,
        child_id=message_record.child_id,
        message=message_record.message_text,
        category=prediction_record.category,
        risk_level=prediction_record.risk_level,
        confidence=prediction_record.confidence,
        explanation=prediction_record.explanation
    )


@router.post(
    "/analyze",
    response_model=AnalyzeResponse
)
def analyze_single_message(
    payload: AnalyzeRequest,
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    child = get_child_for_current_user(
        payload.child_id,
        current_user,
        database_session
    )

    result = save_analyzed_message(
        child,
        payload.message,
        database_session
    )

    database_session.commit()

    return result


@router.post(
    "/analyze/batch",
    response_model=BatchAnalyzeResponse
)
def analyze_batch_messages(
    payload: BatchAnalyzeRequest,
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    if len(payload.messages) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Messages list cannot be empty"
        )

    if len(payload.messages) > 50:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot analyze more than 50 messages at once"
        )

    child = get_child_for_current_user(
        payload.child_id,
        current_user,
        database_session
    )

    results = []

    for message_text in payload.messages:
        if not message_text.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Message text cannot be empty"
            )

        result = save_analyzed_message(
            child,
            message_text,
            database_session
        )

        results.append(result)

    database_session.commit()

    return BatchAnalyzeResponse(
        child_id=child.id,
        total_messages=len(results),
        results=results
    )
