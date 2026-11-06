"""creating_initial_smoothie_tables

Revision ID: 0f2b2c3f7ff5
Revises: 
Create Date: 2026-11-06 08:55:39.889178

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import os


# revision identifiers, used by Alembic.
revision: str = '0f2b2c3f7ff5'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    sql_path = os.path.join(os.path.dirname(__file__), '../sql/V001__initial_core_schema_up.sql')
    with open(sql_path, 'r', encoding='utf-8') as f:
        op.execute(f.read())


def downgrade() -> None:
    sql_path = os.path.join(os.path.dirname(__file__), '../sql/V001__initial_core_schema_down.sql')
    with open(sql_path, 'r', encoding='utf-8') as f:
        op.execute(f.read())
