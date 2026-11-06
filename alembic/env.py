import os
import sys
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool, URL
from alembic import context
from dotenv import load_dotenv

sys.path.append(os.path.join(os.path.dirname(__file__), '../scripts'))
from exceptions import EnvironmentConfigurationError

load_dotenv()

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# 1. Fetch individual components safely
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")
db_host = os.getenv("DB_HOST", "localhost")
db_port = os.getenv("DB_PORT", "5432")
db_name = os.getenv("DB_NAME")

if not all([db_user, db_password, db_name]):
    raise EnvironmentConfigurationError("CRITICAL: Missing required database environment variables.")


database_url = f"postgresql+psycopg://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"

# 3. Inject cleanly into Alembic config
config.set_main_option("sqlalchemy.url", str(database_url))

target_metadata = None

def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )
        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()