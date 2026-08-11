from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status
)
from sqlalchemy.orm import Session

from app.core.security import (
    create_access_token,
    hash_password,
    verify_password
)
from app.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse
)


router = APIRouter(
    prefix="/api/auth",
    tags=["Authentication"]
)


def build_user_response(user: User) -> UserResponse:
    return UserResponse(
        user_id=user.id,
        full_name=user.full_name,
        email=user.email,
        role=user.role,
        created_at=user.created_at
    )


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED
)
def register_user(
    payload: RegisterRequest,
    database_session: Session = Depends(get_db)
):
    normalized_email = str(payload.email).strip().lower()

    existing_user = (
        database_session
        .query(User)
        .filter(User.email == normalized_email)
        .first()
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email is already registered"
        )

    user_record = User(
        full_name=payload.full_name.strip(),
        email=normalized_email,
        password_hash=hash_password(
            payload.password
        ),
        role="Parent"
    )

    database_session.add(user_record)
    database_session.commit()
    database_session.refresh(user_record)

    return build_user_response(user_record)


@router.post(
    "/login",
    response_model=TokenResponse
)
def login_user(
    payload: LoginRequest,
    database_session: Session = Depends(get_db)
):
    normalized_email = str(payload.email).strip().lower()

    user = (
        database_session
        .query(User)
        .filter(User.email == normalized_email)
        .first()
    )

    if (
        user is None
        or not verify_password(
            payload.password,
            user.password_hash
        )
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

    access_token = create_access_token(user.id)

    return TokenResponse(
        access_token=access_token,
        user=build_user_response(user)
    )


@router.get(
    "/me",
    response_model=UserResponse
)
def get_logged_in_user(
    current_user: User = Depends(get_current_user)
):
    return build_user_response(current_user)
