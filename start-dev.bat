@echo off
setlocal
title KnowBase Dev Launcher
cd /d "%~dp0"

echo ================================================
echo          KnowBase Development Mode
echo ================================================
echo.

if not exist "backend\.venv\Scripts\python.exe" (
  echo Backend virtual environment was not found.
  echo Expected: backend\.venv\Scripts\python.exe
  pause
  exit /b 1
)

if not exist "frontend\package.json" (
  echo Frontend package.json was not found.
  pause
  exit /b 1
)

echo [1/2] Starting backend with reload on http://127.0.0.1:8000
start "KnowBase Backend Dev" /MIN cmd /k "cd /d %~dp0backend && .venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload"

echo [2/2] Starting frontend with hot reload on http://localhost:3000
start "KnowBase Frontend Dev" /MIN cmd /k "cd /d %~dp0frontend && npm run dev"

echo.
echo Dev servers are starting in separate windows.
echo Frontend: http://localhost:3000
echo Backend:  http://127.0.0.1:8000
echo.
echo Close the two dev windows to stop the servers.
pause
