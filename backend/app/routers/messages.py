import csv
from io import StringIO
from typing import Optional

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    Query,
    UploadFile,
    status
)
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies.auth import get_current_user
from app.models.child import Child
from app.models.message import Message
from app.models.user import User
from app.routers.analyze import (
    get_child_for_current_user,
    save_analyzed_message
)
from app.schemas.analyze import BatchAnalyzeResponse
from app.schemas.message import MessageResponse


router = APIRouter(
    prefix="/api/messages",
    tags=["Messages"]
)


@router.get(
    "",
    response_model=list[MessageResponse]
)
def get_messages(
    child_id: Optional[int] = Query(
        default=None,
        ge=1
    ),
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    query = (
        database_session
        .query(Message)
        .join(
            Child,
            Message.child_id == Child.id
        )
        .filter(
            Child.parent_id == current_user.id
        )
    )

    if child_id is not None:
        query = query.filter(
            Message.child_id == child_id
        )

    message_records = (
        query
        .order_by(Message.created_at.desc())
        .all()
    )

    return [
        MessageResponse(
            message_id=message_record.id,
            child_id=message_record.child_id,
            message=message_record.message_text,
            category=message_record.prediction.category,
            risk_level=message_record.prediction.risk_level,
            confidence=message_record.prediction.confidence,
            explanation=message_record.prediction.explanation,
            created_at=message_record.created_at
        )
        for message_record in message_records
        if message_record.prediction is not None
    ]


@router.post(
    "/upload",
    response_model=BatchAnalyzeResponse
)
async def upload_messages_csv(
    child_id: int = Form(..., ge=1),
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    child = get_child_for_current_user(
        child_id,
        current_user,
        database_session
    )

    if file.filename is None or not file.filename.endswith(".csv"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only CSV files are supported"
        )

    file_content = await file.read()

    try:
        csv_text = file_content.decode("utf-8-sig")
    except UnicodeDecodeError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="CSV file must be UTF-8 encoded"
        )

    reader = csv.DictReader(
        StringIO(csv_text)
    )

    if reader.fieldnames is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="CSV file is empty"
        )

    if "message" not in reader.fieldnames:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="CSV file must contain a message column"
        )

    messages = []

    for row in reader:
        message_text = (
            row.get("message") or ""
        ).strip()

        if message_text:
            messages.append(message_text)

    if len(messages) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="CSV file does not contain valid messages"
        )

    if len(messages) > 50:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot analyze more than 50 messages at once"
        )

    results = []

    for message_text in messages:
        result = save_analyzed_message(
            child,
            message_text,
            database_session
        )

        results.append(result)

    database_session.commit()

    return BatchAnalyzeResponse(
        child_id=child.id,
        total_messages=len(results),
        results=results
    )
