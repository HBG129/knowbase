@echo off
title KnowBase
cd /d "%~dp0"

echo ================================================
echo          KnowBase - AI Knowledge Base
echo ================================================
echo.

echo [1/2] Starting backend...
start "KnowBase-Backend" /MIN cmd /c "cd /d %~dp0backend && .venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000"

echo [2/2] Starting frontend...
start "KnowBase-Frontend" /MIN cmd /c "cd /d %~dp0frontend && npx next dev -p 3000"

echo.
echo Waiting 10 seconds for servers...
timeout /t 10 /nobreak

echo Opening browser...
start http://localhost:3000

echo.
echo ================================================
echo   http://localhost:3000
echo ================================================
echo.
echo Press any key to stop all services...
pause >nul

taskkill /FI "WINDOWTITLE eq KnowBase-Backend*" /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq KnowBase-Frontend*" /F >nul 2>&1
