

class DatabaseMigrationError(Exception):
    """Base exception class for all database migration errors"""
    pass


class DatabaseConnectionError(DatabaseMigrationError):
    """Raised when the database connection times out or fails completely"""
    def __init__(self, message="Failed to establish database connection."):
        super().__init__(message)
        
class EnvironmentConfigurationError(DatabaseMigrationError):
    """Raised when environment variables are missing or misconfigured"""
    def __init__(self, message="Environment variables are missing."):
        super().__init__(message)        