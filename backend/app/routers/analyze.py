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
from app.schemas.analyze import AnalyzeRequest, AnalyzeResponse
from app.services.classifier import analyze_message


router = APIRouter(
    prefix="/api",
    tags=["Message Analysis"]
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
    child = (
        database_session
        .query(Child)
        .filter(
            Child.id == payload.child_id,
            Child.parent_id == current_user.id
        )
        .first()
    )

    if child is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Child not found"
        )

    analysis_result = analyze_message(payload.message)

    message_record = Message(
        child_id=child.id,
        message_text=payload.message
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

    database_session.commit()
    database_session.refresh(message_record)

    return AnalyzeResponse(
        message_id=message_record.id,
        child_id=message_record.child_id,
        message=message_record.message_text,
        category=prediction_record.category,
        risk_level=prediction_record.risk_level,
        confidence=prediction_record.confidence,
        explanation=prediction_record.explanation
    )
