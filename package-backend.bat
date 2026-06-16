@echo off
setlocal EnableExtensions
title KnowBase Backend Packager
cd /d "%~dp0"

set "BACKEND_DIR=%~dp0backend"
set "PY=%BACKEND_DIR%\.venv\Scripts\python.exe"
if not defined CONDA_DLL_DIR set "CONDA_DLL_DIR=D:\Anaconda\Library\bin"
if not defined PIP_CACHE_DIR (
  for %%I in ("%~dp0..\.tools\pip-cache") do set "PIP_CACHE_DIR=%%~fI"
)
if not defined PYINSTALLER_CONFIG_DIR (
  for %%I in ("%~dp0..\.tools\pyinstaller-cache") do set "PYINSTALLER_CONFIG_DIR=%%~fI"
)

echo ================================================
echo        KnowBase Backend EXE Packaging
echo ================================================
echo.

if not exist "%PY%" (
  echo Backend virtual environment was not found.
  echo Expected: backend\.venv\Scripts\python.exe
  echo.
  echo Create it with Python 3.12 before packaging.
  if not "%KNOWBASE_NO_PAUSE%"=="1" pause
  exit /b 1
)

"%PY%" -c "import PyInstaller" >nul 2>nul
if errorlevel 1 (
  echo Installing packaging dependencies into backend\.venv...
  "%PY%" -m pip install pyinstaller
  if errorlevel 1 (
    echo Failed to install PyInstaller.
    if not "%KNOWBASE_NO_PAUSE%"=="1" pause
    exit /b 1
  )
)

cd /d "%BACKEND_DIR%"
for %%I in ("%BACKEND_DIR%") do set "BACKEND_RESOLVED=%%~fI"
if /I not "%CD%"=="%BACKEND_RESOLVED%" (
  echo Refusing to clean build output outside backend directory.
  if not "%KNOWBASE_NO_PAUSE%"=="1" pause
  exit /b 1
)

if not exist "%CONDA_DLL_DIR%\libssl-3-x64.dll" (
  echo Required Anaconda DLLs were not found.
  echo Expected: %CONDA_DLL_DIR%\libssl-3-x64.dll
  echo.
  echo Set CONDA_DLL_DIR to the directory containing Anaconda runtime DLLs.
  if not "%KNOWBASE_NO_PAUSE%"=="1" pause
  exit /b 1
)
if not exist "%CONDA_DLL_DIR%\sqlite3.dll" (
  echo Required SQLite DLL was not found.
  echo Expected: %CONDA_DLL_DIR%\sqlite3.dll
  echo.
  echo Set CONDA_DLL_DIR to the directory containing Anaconda runtime DLLs.
  if not "%KNOWBASE_NO_PAUSE%"=="1" pause
  exit /b 1
)

echo Cleaning previous backend package output...
if exist "build\KnowBaseBackend" rmdir /s /q "build\KnowBaseBackend"
if exist "dist\KnowBaseBackend.exe" del /q "dist\KnowBaseBackend.exe"
if exist "KnowBaseBackend.spec" del /q "KnowBaseBackend.spec"

echo Building backend executable...
"%PY%" -m PyInstaller ^
  --name KnowBaseBackend ^
  --onefile ^
  --clean ^
  --noconfirm ^
  --paths "%BACKEND_DIR%" ^
  --add-binary "%CONDA_DLL_DIR%\libssl-3-x64.dll;." ^
  --add-binary "%CONDA_DLL_DIR%\libcrypto-3-x64.dll;." ^
  --add-binary "%CONDA_DLL_DIR%\liblzma.dll;." ^
  --add-binary "%CONDA_DLL_DIR%\libbz2.dll;." ^
  --add-binary "%CONDA_DLL_DIR%\libexpat.dll;." ^
  --add-binary "%CONDA_DLL_DIR%\ffi.dll;." ^
  --add-binary "%CONDA_DLL_DIR%\sqlite3.dll;." ^
  --hidden-import passlib.handlers.bcrypt ^
  desktop_server.py

if errorlevel 1 (
  echo Backend executable build failed.
  if not "%KNOWBASE_NO_PAUSE%"=="1" pause
  exit /b 1
)

echo.
echo Backend executable created:
echo   backend\dist\KnowBaseBackend.exe
echo.
if not "%KNOWBASE_NO_PAUSE%"=="1" pause
