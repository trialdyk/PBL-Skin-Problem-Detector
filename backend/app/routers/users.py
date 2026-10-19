"""User-related API routes.

Endpoints in this module only verify router registration for PBL-04.
Business features (registration, login, profile) are deferred.
"""

from fastapi import APIRouter

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/status")
def users_status() -> dict[str, str]:
    """Informational endpoint confirming the users router is registered."""
    return {
        "router": "users",
        "status": "registered",
        "note": "Placeholder only — no user business features in PBL-04",
    }
