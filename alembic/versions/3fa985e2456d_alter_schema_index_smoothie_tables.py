"""alter_schema_index_smoothie_tables

Revision ID: 3fa985e2456d
Revises: 00484a8120a9
Create Date: 2026-11-06 11:32:41.564909

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import os


# revision identifiers, used by Alembic.
revision: str = '3fa985e2456d'
down_revision: Union[str, None] = '00484a8120a9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    sql_path = os.path.join(os.path.dirname(__file__), '../sql/V001__initial_core_alter_indexes_up.sql' )
    with open(sql_path, 'r', encoding='utf-8') as f:
        op.execute(f.read())

def downgrade() -> None:
    pass
