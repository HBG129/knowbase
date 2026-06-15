@echo off
chcp 65001 >nul
title KnowBase
cd /d "%~dp0"

echo.
echo ================================================
echo          KnowBase - AI Knowledge Base
echo          UTF-8 Console Launcher
echo ================================================
echo.

echo [1/2] Starting backend...
start "KnowBase-Backend" /MIN cmd /c "cd /d %~dp0backend && .venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000"
echo       Backend:  http://127.0.0.1:8000

echo [2/2] Starting frontend...
start "KnowBase-Frontend" /MIN cmd /c "cd /d %~dp0frontend && npx next dev -p 3000"
echo       Frontend: http://localhost:3000

echo.
echo Waiting 8 seconds for servers...
timeout /t 8 /nobreak >nul

echo Opening browser...
start http://localhost:3000

echo.
echo ================================================
echo   KnowBase is starting.
echo   Press any key here to stop child services.
echo ================================================
pause >nul

echo Stopping services...
taskkill /FI "WINDOWTITLE eq KnowBase-Backend*" /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq KnowBase-Frontend*" /F >nul 2>&1
echo Stopped.
timeout /t 2 /nobreak >nul
