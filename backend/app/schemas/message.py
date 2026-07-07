from datetime import datetime
from typing import Literal

from pydantic import BaseModel


Category = Literal[
    "Normal",
    "Insult",
    "Threat",
    "Harassment",
    "Bullying"
]

RiskLevel = Literal[
    "Low",
    "Medium",
    "High"
]


class MessageResponse(BaseModel):
    message_id: int
    child_id: int
    message: str
    category: Category
    risk_level: RiskLevel
    confidence: float
    explanation: str
    created_at: datetime
