from fastapi import APIRouter

from app.schemas.analyze import AnalyzeRequest, AnalyzeResponse
from app.services.classifier import analyze_message


router = APIRouter(
    prefix="/api",
    tags=["Message Analysis"]
)


@router.post("/analyze", response_model=AnalyzeResponse)
def analyze_single_message(payload: AnalyzeRequest):
    result = analyze_message(payload.message)

    return AnalyzeResponse(
        message_id=None,
        child_id=payload.child_id,
        message=payload.message,
        category=result["category"],
        risk_level=result["risk_level"],
        confidence=result["confidence"],
        explanation=result["explanation"]
    )
