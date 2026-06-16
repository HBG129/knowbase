@echo off
setlocal EnableExtensions
title KnowBase Desktop Packager
cd /d "%~dp0"

if not defined KNOWBASE_NO_PAUSE set "PACKAGE_DESKTOP_PAUSE=1"
set "KNOWBASE_NO_PAUSE=1"

for %%I in ("%~dp0..\.tools") do set "TOOLS_ROOT=%%~fI"
set "RUSTUP_HOME=%TOOLS_ROOT%\rustup"
set "CARGO_HOME=%TOOLS_ROOT%\cargo"
set "PIP_CACHE_DIR=%TOOLS_ROOT%\pip-cache"
set "PYINSTALLER_CONFIG_DIR=%TOOLS_ROOT%\pyinstaller-cache"
set "npm_config_cache=%TOOLS_ROOT%\npm-cache"
set "PATH=%CARGO_HOME%\bin;%PATH%"

echo ================================================
echo          KnowBase Desktop Packaging
echo ================================================
echo.
echo Tools root:
echo   %TOOLS_ROOT%
echo.

echo [1/3] Checking desktop prerequisites...
call "%~dp0check-desktop-prereqs.bat"
if errorlevel 1 (
  echo.
  echo Desktop packaging stopped: prerequisites are incomplete.
  echo Install the missing tools above, then run package-desktop.bat again.
  if "%PACKAGE_DESKTOP_PAUSE%"=="1" pause
  exit /b 1
)
cd /d "%~dp0"

echo.
echo [2/3] Building backend executable...
call "%~dp0package-backend.bat"
if errorlevel 1 (
  echo.
  echo Desktop packaging stopped: backend executable build failed.
  if "%PACKAGE_DESKTOP_PAUSE%"=="1" pause
  exit /b 1
)
cd /d "%~dp0"

if not exist "%~dp0backend\dist\KnowBaseBackend.exe" (
  echo.
  echo Desktop packaging stopped: backend executable was not created.
  if "%PACKAGE_DESKTOP_PAUSE%"=="1" pause
  exit /b 1
)

echo.
echo [3/3] Building Tauri desktop bundle...
if not exist "%~dp0frontend\node_modules" (
  echo Frontend dependencies were not found.
  echo Run npm install in frontend before packaging.
  if "%PACKAGE_DESKTOP_PAUSE%"=="1" pause
  exit /b 1
)

cd /d "%~dp0frontend"
call npm run tauri:build
if errorlevel 1 (
  echo.
  echo Desktop packaging stopped: Tauri build failed.
  if "%PACKAGE_DESKTOP_PAUSE%"=="1" pause
  exit /b 1
)

echo.
echo Desktop package output:
echo   frontend\src-tauri\target\release\bundle
echo.
if "%PACKAGE_DESKTOP_PAUSE%"=="1" pause
exit /b 0
