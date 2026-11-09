"""User-related API routes.

Endpoints in this module only verify router registration for PBL-04.
Business features (profile) are deferred; login and registration live in ``auth.py``.
"""

from fastapi import APIRouter, Depends

from app.dependencies import get_current_user
from app.schemas.auth import ErrorResponse

router = APIRouter(
    prefix="/users",
    tags=["users"],
    dependencies=[Depends(get_current_user)],
)


@router.get(
    "/status",
    summary="Confirm the users router is registered",
    responses={
        401: {
            "model": ErrorResponse,
            "description": "Missing, invalid, expired, or inactive-user bearer token.",
        },
    },
)
def users_status() -> dict[str, str]:
    """Informational endpoint confirming the users router is registered.

    Requires ``Authorization: Bearer <access_token>`` from login/register.
    """
    return {
        "router": "users",
        "status": "registered",
        "note": "Placeholder only — no user business features in PBL-04",
    }
