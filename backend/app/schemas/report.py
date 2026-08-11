from datetime import datetime

from pydantic import BaseModel


class ReportMessageResponse(BaseModel):
    message_id: int
    child_id: int
    child_name: str
    message: str
    category: str
    risk_level: str
    confidence: float
    explanation: str
    created_at: datetime


class ChildReportSummary(BaseModel):
    child_id: int
    child_name: str
    total_messages: int
    high_risk_messages: int


class ReportSummaryResponse(BaseModel):
    total_children: int
    total_messages: int
    high_risk_messages: int
    unread_alerts: int
    messages_by_risk_level: dict[str, int]
    messages_by_category: dict[str, int]
    messages_by_child: list[ChildReportSummary]
