"""add attachment name and descriptions

Revision ID: 8c2e3f1a9b74
Revises: 72a371ed24e9
Create Date: 2026-11-19
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "8c2e3f1a9b74"
down_revision: Union[str, Sequence[str], None] = "72a371ed24e9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("Attachments", sa.Column("name", sa.String(length=255), nullable=True))
    op.add_column("Attachments", sa.Column("destiption_uk", sa.Text(), nullable=True))
    op.add_column("Attachments", sa.Column("destiption_en", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("Attachments", "destiption_en")
    op.drop_column("Attachments", "destiption_uk")
    op.drop_column("Attachments", "name")
