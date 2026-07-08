from fastapi import Depends, HTTPException, status
from fastapi.security import (
    HTTPAuthorizationCredentials,
    HTTPBearer
)
from jose import JWTError
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.database import get_db
from app.models.user import User


bearer_scheme = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(
        bearer_scheme
    ),
    database_session: Session = Depends(get_db)
) -> User:
    credentials_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired authentication token",
        headers={
            "WWW-Authenticate": "Bearer"
        }
    )

    try:
        payload = decode_access_token(
            credentials.credentials
        )

        user_id_value = payload.get("sub")

        if user_id_value is None:
            raise credentials_error

        user_id = int(user_id_value)

    except (JWTError, TypeError, ValueError):
        raise credentials_error

    user = database_session.get(User, user_id)

    if user is None:
        raise credentials_error

    return user
