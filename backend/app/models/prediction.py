from datetime import datetime, timezone

from sqlalchemy import (
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text
)
from sqlalchemy.orm import relationship

from app.database import Base


class Prediction(Base):
    __tablename__ = "predictions"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    message_id = Column(
        Integer,
        ForeignKey("messages.id"),
        nullable=False,
        unique=True,
        index=True
    )

    category = Column(
        String(50),
        nullable=False
    )

    risk_level = Column(
        String(20),
        nullable=False
    )

    confidence = Column(
        Float,
        nullable=False
    )

    explanation = Column(
        Text,
        nullable=False
    )

    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    message = relationship(
        "Message",
        back_populates="prediction"
    )
