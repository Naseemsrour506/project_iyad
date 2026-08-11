from datetime import datetime

from pydantic import BaseModel, Field


class ChildCreate(BaseModel):
    full_name: str = Field(
        ...,
        min_length=2,
        max_length=120
    )

    age: int = Field(
        ...,
        ge=1,
        le=18
    )


class ChildResponse(BaseModel):
    child_id: int
    parent_id: int
    full_name: str
    age: int
    created_at: datetime
