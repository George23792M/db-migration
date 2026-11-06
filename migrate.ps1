# Run Database Migrations Script for db-migrations repo
Write-Host "Checking for any running migration processes..." -ForegroundColor Yellow

# Clean up any lingering python migration processes if needed
Get-Process python -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*db-migrations*" } | Stop-Process -Force

Start-Sleep -Seconds 1

# 1. Run database health check
Write-Host "Checking database availability at localhost:5432..." -ForegroundColor Cyan
python scripts/check_db_connection.py

if ($LASTEXITCODE -ne 0) {
    Write-Host "Database health check failed! Aborting migrations." -ForegroundColor Red
    exit 1
}

# 2. Run Alembic database migrations (executes raw SQL up files)
Write-Host "Running database migrations (alembic upgrade head)..." -ForegroundColor Cyan
alembic upgrade head

if ($LASTEXITCODE -ne 0) {
    Write-Host "Database migrations failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Database migrations completed successfully!" -ForegroundColor Green