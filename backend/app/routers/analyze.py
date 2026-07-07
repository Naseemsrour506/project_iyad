from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.message import Message
from app.models.prediction import Prediction
from app.schemas.analyze import AnalyzeRequest, AnalyzeResponse
from app.services.classifier import analyze_message


router = APIRouter(
    prefix="/api",
    tags=["Message Analysis"]
)


@router.post("/analyze", response_model=AnalyzeResponse)
def analyze_single_message(
    payload: AnalyzeRequest,
    database_session: Session = Depends(get_db)
):
    analysis_result = analyze_message(payload.message)

    message_record = Message(
        child_id=payload.child_id,
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
