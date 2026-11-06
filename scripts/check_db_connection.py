import os
import sys
import time
import logging
import psycopg
from dotenv import load_dotenv

from exceptions import DatabaseConnectionError, EnvironmentConfigurationError

# Enterprise-grade logging framework
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger("db_health_check")

load_dotenv()

db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")
db_host = os.getenv("DB_HOST", "localhost")
db_port = os.getenv("DB_PORT", "5432")
db_name = os.getenv("DB_NAME")

database_url = os.getenv("DATABASE_URL") or f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"

if not db_user or not db_password or not db_name:
    logger.error("Missing critical database configuration variables in environment.")
    raise EnvironmentConfigurationError("Database user, password, and name must be specified.")

def check_db() -> None:
    logger.info(f"Checking database availability at {db_host}:{db_port}/{db_name}...")
    max_retries = 30
    
    for attempt in range(1, max_retries + 1):
        try:
            conn = psycopg.connect(database_url)
            conn.close()
            logger.info("Database is online, responsive, and ready for migrations!")
            return
        except psycopg.OperationalError:
            logger.warning(f"Database not ready yet (Attempt {attempt}/{max_retries}). Retrying in 2s...")
            time.sleep(2)
            
    logger.critical("Database connection timeout reached. Aborting startup sequence.")
    raise DatabaseConnectionError(f"Could not connect to database at {db_host}:{db_port} after {max_retries} attempts.")

if __name__ == "__main__":
    try:
        check_db()
    except Exception as err:
        logger.exception(f"Fatal error during database health check: {err}")
        sys.exit(1)