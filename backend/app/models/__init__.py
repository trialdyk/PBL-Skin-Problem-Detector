"""ORM models. Import here so they register on ``Base.metadata``."""

from app.models.user import User

__all__ = ["User"]
