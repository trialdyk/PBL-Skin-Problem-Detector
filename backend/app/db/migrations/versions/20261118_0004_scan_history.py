"""create scan_histories and scan_recommendations

Revision ID: 20261118_0004
Revises: 20261117_0003
Create Date: 2026-11-18 00:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "20261118_0004"
down_revision: Union[str, None] = "20261117_0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "scan_histories",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("model_id", sa.String(length=128), nullable=False),
        sa.Column("grade", sa.Integer(), nullable=False),
        sa.Column("grade_label", sa.String(length=64), nullable=False),
        sa.Column("top_label", sa.String(length=32), nullable=True),
        sa.Column("result_source", sa.String(length=32), nullable=False),
        sa.Column("aggregate_json", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("interview_json", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("photo_front_path", sa.String(length=512), nullable=False),
        sa.Column("photo_left_path", sa.String(length=512), nullable=False),
        sa.Column("photo_right_path", sa.String(length=512), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_scan_histories_user_id"), "scan_histories", ["user_id"], unique=False)
    op.create_index(
        op.f("ix_scan_histories_created_at"),
        "scan_histories",
        ["created_at"],
        unique=False,
    )

    op.create_table(
        "scan_recommendations",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("history_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "status",
            sa.String(length=32),
            server_default="pending",
            nullable=False,
        ),
        sa.Column("text", sa.Text(), nullable=True),
        sa.Column("meta_json", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["history_id"], ["scan_histories.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("history_id"),
    )


def downgrade() -> None:
    op.drop_table("scan_recommendations")
    op.drop_index(op.f("ix_scan_histories_created_at"), table_name="scan_histories")
    op.drop_index(op.f("ix_scan_histories_user_id"), table_name="scan_histories")
    op.drop_table("scan_histories")
