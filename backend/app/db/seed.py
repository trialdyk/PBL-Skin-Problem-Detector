"""Create the demo account used by the mobile app: ``python -m app.db.seed``."""

from sqlalchemy import select

from app.core.config import get_settings
from app.core.security import hash_password
from app.db.database import SessionLocal
from app.models import User

DEMO_EMAIL = "pengguna@gmail.com"
DEMO_PASSWORD = "skinscan123"
DEMO_FULL_NAME = "Pengguna Demo"


def seed_demo_user() -> None:
    """Insert the demo user if missing. Development only: the password is public."""
    if get_settings().app_env != "development":
        raise SystemExit("Seed demo hanya untuk APP_ENV=development.")

    with SessionLocal() as db:
        if db.scalar(select(User).where(User.email == DEMO_EMAIL)) is not None:
            print(f"Sudah ada: {DEMO_EMAIL}")
            return
        db.add(
            User(
                email=DEMO_EMAIL,
                password_hash=hash_password(DEMO_PASSWORD),
                full_name=DEMO_FULL_NAME,
            )
        )
        db.commit()
        print(f"Dibuat: {DEMO_EMAIL}")


if __name__ == "__main__":
    seed_demo_user()
