"""Item-related API routes.

Endpoints in this module only verify router registration for PBL-04.
Business features (CRUD) are deferred.
"""

from fastapi import APIRouter, Depends

from app.dependencies import get_current_user
from app.schemas.auth import ErrorResponse

router = APIRouter(
    prefix="/items",
    tags=["items"],
    dependencies=[Depends(get_current_user)],
)


@router.get(
    "/status",
    summary="Confirm the items router is registered",
    responses={
        401: {
            "model": ErrorResponse,
            "description": "Missing, invalid, expired, or inactive-user bearer token.",
        },
    },
)
def items_status() -> dict[str, str]:
    """Informational endpoint confirming the items router is registered.

    Requires ``Authorization: Bearer <access_token>`` from login/register.
    """
    return {
        "router": "items",
        "status": "registered",
        "note": "Placeholder only — no item business features in PBL-04",
    }
