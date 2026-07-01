from typing import Literal, Optional
from pydantic import BaseModel, Field


Category = Literal["Normal", "Insult", "Threat", "Harassment", "Bullying"]
RiskLevel = Literal["Low", "Medium", "High"]


class AnalyzeRequest(BaseModel):
    child_id: int = Field(..., ge=1)
    message: str = Field(..., min_length=1)


class AnalyzeResponse(BaseModel):
    message_id: Optional[int] = None
    child_id: int
    message: str
    category: Category
    risk_level: RiskLevel
    confidence: float
    explanation: str
