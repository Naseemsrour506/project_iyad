from pydantic import BaseModel


class DashboardStatsResponse(BaseModel):
    total_children: int
    total_messages: int
    risk_levels: dict[str, int]
    categories: dict[str, int]
