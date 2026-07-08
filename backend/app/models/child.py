from datetime import datetime, timezone

from sqlalchemy import CheckConstraint, Column, DateTime, Integer, String
from sqlalchemy.orm import relationship

from app.database import Base


class Child(Base):
    __tablename__ = "children"

    __table_args__ = (
        CheckConstraint(
            "age >= 1 AND age <= 18",
            name="check_child_age"
        ),
    )

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    parent_id = Column(
        Integer,
        nullable=False,
        index=True
    )

    full_name = Column(
        String(120),
        nullable=False
    )

    age = Column(
        Integer,
        nullable=False
    )

    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    messages = relationship(
        "Message",
        back_populates="child",
        cascade="all, delete-orphan"
    )
