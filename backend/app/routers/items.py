"""Item-related API routes.

Endpoints in this module only verify router registration for PBL-04.
Business features (CRUD) are deferred.
"""

from fastapi import APIRouter

router = APIRouter(prefix="/items", tags=["items"])


@router.get("/status")
def items_status() -> dict[str, str]:
    """Informational endpoint confirming the items router is registered."""
    return {
        "router": "items",
        "status": "registered",
        "note": "Placeholder only — no item business features in PBL-04",
    }
