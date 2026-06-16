@echo off
setlocal EnableExtensions
title KnowBase Dev Launcher
cd /d "%~dp0"

set "BACKEND_PY=backend\.venv\Scripts\python.exe"
set "NEXT_BIN=frontend\node_modules\.bin\next.cmd"

echo ================================================
echo          KnowBase Development Mode
echo ================================================
echo.

if not exist "%BACKEND_PY%" goto missing_backend_venv

"%BACKEND_PY%" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 12) else 1)" >nul 2>nul
if errorlevel 1 goto bad_python_version

"%BACKEND_PY%" -c "import fastapi, uvicorn" >nul 2>nul
if errorlevel 1 goto missing_backend_deps

if not exist "frontend\package.json" goto missing_frontend

where node >nul 2>nul
if errorlevel 1 goto missing_node

where npm >nul 2>nul
if errorlevel 1 goto missing_npm

if not exist "%NEXT_BIN%" goto missing_frontend_deps

echo Checks passed.
echo.
echo Backend:  http://127.0.0.1:8000
echo Frontend: http://localhost:3000
echo.

echo [1/2] Starting backend with reload
start "KnowBase Backend Dev" /MIN cmd /k "cd /d %~dp0backend && .venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload"

echo [2/2] Starting frontend with hot reload
start "KnowBase Frontend Dev" /MIN cmd /k "cd /d %~dp0frontend && npm run dev"

echo.
echo Dev servers are starting in separate windows.
echo Close the two dev windows to stop the servers.
pause
exit /b 0

:missing_backend_venv
echo Backend virtual environment was not found.
echo Expected: %BACKEND_PY%
echo.
echo Create it with Python 3.12, for example:
echo   D:\Anaconda\python.exe -m venv backend\.venv
echo.
pause
exit /b 1

:bad_python_version
echo Backend virtual environment must use Python 3.12 or newer.
echo Current version:
"%BACKEND_PY%" --version
echo.
echo Recreate backend\.venv with a working Python 3.12 interpreter.
pause
exit /b 1

:missing_backend_deps
echo Backend dependencies are missing.
echo.
echo Run:
echo   cd backend
echo   .venv\Scripts\python.exe -c "import subprocess, sys, tomllib; p=tomllib.load(open('pyproject.toml','rb'))['project']; deps=p['dependencies']+p['optional-dependencies']['dev']; subprocess.check_call([sys.executable,'-m','pip','install',*deps])"
echo.
pause
exit /b 1

:missing_frontend
echo Frontend package.json was not found.
echo Expected: frontend\package.json
pause
exit /b 1

:missing_node
echo Node.js was not found on PATH.
echo Install Node.js 20 or newer, then run this launcher again.
pause
exit /b 1

:missing_npm
echo npm was not found on PATH.
echo Install Node.js 20 or newer, then run this launcher again.
pause
exit /b 1

:missing_frontend_deps
echo Frontend dependencies are missing.
echo.
echo Run:
echo   cd frontend
echo   npm install
echo.
pause
exit /b 1
