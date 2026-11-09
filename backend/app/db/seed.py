"""Create the demo account: ``python -m app.db.seed``.

Production requires an explicit flag:

    python -m app.db.seed --force
"""

from __future__ import annotations

import argparse
import sys

from sqlalchemy import select

from app.core.config import get_settings
from app.core.security import hash_password
from app.db.database import SessionLocal
from app.models import User

DEMO_EMAIL = "pengguna@gmail.com"
DEMO_PASSWORD = "skinscan123"
DEMO_FULL_NAME = "Pengguna Demo"


def seed_demo_user(*, force: bool = False) -> None:
    """Insert the demo user if missing.

    Development runs freely. Outside development, pass ``force=True`` / ``--force``.
    """
    settings = get_settings()
    if settings.app_env != "development" and not force:
        raise SystemExit(
            "Seed demo ditolak di luar APP_ENV=development. "
            "Kalau sengaja (mis. isi akun uji di production), jalankan: "
            "python -m app.db.seed --force"
        )

    with SessionLocal() as db:
        existing = db.scalar(select(User).where(User.email == DEMO_EMAIL))
        if existing is not None:
            print(f"Sudah ada: {DEMO_EMAIL}")
            return
        db.add(
            User(
                email=DEMO_EMAIL,
                password_hash=hash_password(DEMO_PASSWORD),
                full_name=DEMO_FULL_NAME,
                auth_provider="password",
            )
        )
        db.commit()
        print(f"Dibuat: {DEMO_EMAIL}")


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Seed DermaScan demo user")
    parser.add_argument(
        "--force",
        action="store_true",
        help="Allow seeding when APP_ENV is not development",
    )
    args = parser.parse_args(argv)
    seed_demo_user(force=args.force)


if __name__ == "__main__":
    main(sys.argv[1:])
