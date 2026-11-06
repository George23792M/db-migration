"""create_email_table

Revision ID: 00484a8120a9
Revises: 0f2b2c3f7ff5
Create Date: 2026-11-06 10:04:13.823236

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import os


# revision identifiers, used by Alembic.
revision: str = '00484a8120a9'
down_revision: Union[str, None] = '0f2b2c3f7ff5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    sql_path = os.path.join(os.path.dirname(__file__), '../sql/V002__create_email.sql' )
    with open(sql_path, 'r', encoding='utf-8') as f:
        op.execute(f.read())

def downgrade() -> None:
    pass
