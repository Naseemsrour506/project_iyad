from datetime import datetime

from pydantic import BaseModel


class AlertResponse(BaseModel):
    alert_id: int
    child_id: int
    message_id: int
    title: str
    category: str
    risk_level: str
    is_read: bool
    created_at: datetime


class UnreadAlertsCountResponse(BaseModel):
    unread_count: int
