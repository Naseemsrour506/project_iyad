from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status
)
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies.auth import get_current_user
from app.models.child import Child
from app.models.user import User
from app.schemas.child import ChildCreate, ChildResponse


router = APIRouter(
    prefix="/api/children",
    tags=["Children"]
)


def build_child_response(child: Child) -> ChildResponse:
    return ChildResponse(
        child_id=child.id,
        parent_id=child.parent_id,
        full_name=child.full_name,
        age=child.age,
        created_at=child.created_at
    )


@router.post(
    "",
    response_model=ChildResponse,
    status_code=status.HTTP_201_CREATED
)
def create_child(
    payload: ChildCreate,
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    child_record = Child(
        parent_id=current_user.id,
        full_name=payload.full_name.strip(),
        age=payload.age
    )

    database_session.add(child_record)
    database_session.commit()
    database_session.refresh(child_record)

    return build_child_response(child_record)


@router.get(
    "",
    response_model=list[ChildResponse]
)
def get_children(
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    children = (
        database_session
        .query(Child)
        .filter(Child.parent_id == current_user.id)
        .order_by(Child.created_at.desc())
        .all()
    )

    return [
        build_child_response(child)
        for child in children
    ]


@router.get(
    "/{child_id}",
    response_model=ChildResponse
)
def get_child(
    child_id: int,
    current_user: User = Depends(get_current_user),
    database_session: Session = Depends(get_db)
):
    child = (
        database_session
        .query(Child)
        .filter(
            Child.id == child_id,
            Child.parent_id == current_user.id
        )
        .first()
    )

    if child is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Child not found"
        )

    return build_child_response(child)
