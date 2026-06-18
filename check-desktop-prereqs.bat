@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "FAIL=0"
for %%I in ("%~dp0..\.tools") do set "TOOLS_ROOT=%%~fI"
if not defined RUSTUP_HOME if exist "%TOOLS_ROOT%\rustup" set "RUSTUP_HOME=%TOOLS_ROOT%\rustup"
if not defined CARGO_HOME if exist "%TOOLS_ROOT%\cargo\bin\cargo.exe" set "CARGO_HOME=%TOOLS_ROOT%\cargo"
if defined CARGO_HOME set "PATH=%CARGO_HOME%\bin;%PATH%"

echo ================================================
echo       KnowBase Desktop Prerequisite Check
echo ================================================
echo.

echo [Workspace tools]
echo %TOOLS_ROOT%
echo.

echo [Node.js]
where node >nul 2>nul
if errorlevel 1 (
  echo ERROR: node was not found on PATH.
  set "FAIL=1"
) else (
  node --version
)
echo.

echo [npm]
where npm >nul 2>nul
if errorlevel 1 (
  echo ERROR: npm was not found on PATH.
  set "FAIL=1"
) else (
  call npm --version
)
echo.

echo [Rust]
where rustc >nul 2>nul
if errorlevel 1 (
  echo ERROR: rustc was not found. Run setup-rust-env.bat or install Rust.
  set "FAIL=1"
) else (
  rustc --version
)
echo.

echo [Cargo]
where cargo >nul 2>nul
if errorlevel 1 (
  echo ERROR: cargo was not found. Run setup-rust-env.bat or install Rust.
  set "FAIL=1"
) else (
  cargo --version
)
echo.

echo [Microsoft C++ Build Tools]
call :CheckMsvcTools
if errorlevel 1 (
  set "FAIL=1"
  echo.
  echo Install hint:
  echo   Install Microsoft C++ Build Tools and select:
  echo   - Desktop development with C++
  echo   Then restart this terminal and rerun:
  echo   .\check-desktop-prereqs.bat
  echo.
  echo Official Tauri Windows prerequisites:
  echo   https://v2.tauri.app/start/prerequisites/
  echo.
  echo KnowBase troubleshooting:
  echo   docs\desktop-build-troubleshooting.md
  echo.
  echo Common Visual Studio developer shell locations:
  if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat" echo   FOUND: "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"
  if exist "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat" echo   FOUND: "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"
  if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat" echo   FOUND: "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat"
  if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" echo   FOUND: "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"
  if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" echo   FOUND: "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"
  if exist "%ProgramFiles%\Microsoft Visual Studio\2026\Enterprise\Common7\Tools\VsDevCmd.bat" echo   FOUND: "%ProgramFiles%\Microsoft Visual Studio\2026\Enterprise\Common7\Tools\VsDevCmd.bat"
  if exist "%ProgramFiles%\Microsoft Visual Studio\2026\BuildTools\Common7\Tools\VsDevCmd.bat" echo   FOUND: "%ProgramFiles%\Microsoft Visual Studio\2026\BuildTools\Common7\Tools\VsDevCmd.bat"
  if exist "%ProgramFiles%\Microsoft Visual Studio\2026\Community\Common7\Tools\VsDevCmd.bat" echo   FOUND: "%ProgramFiles%\Microsoft Visual Studio\2026\Community\Common7\Tools\VsDevCmd.bat"
)
echo.

echo [Backend executable]
if exist "backend\dist\KnowBaseBackend.exe" (
  echo backend\dist\KnowBaseBackend.exe found.
) else (
  echo WARN: backend\dist\KnowBaseBackend.exe was not found.
  echo       Run package-backend.bat before testing packaged desktop startup.
)
echo.

echo [Tauri manifest]
if exist "frontend\src-tauri\tauri.conf.json" (
  echo frontend\src-tauri\tauri.conf.json found.
) else (
  echo ERROR: Tauri config was not found.
  set "FAIL=1"
)
echo.

echo [Tauri Windows icon]
if exist "frontend\src-tauri\icons\icon.ico" (
  echo frontend\src-tauri\icons\icon.ico found.
) else (
  echo ERROR: Tauri Windows icon was not found.
  echo        Expected: frontend\src-tauri\icons\icon.ico
  set "FAIL=1"
)
echo.

if "%FAIL%"=="1" (
  echo Result: desktop prerequisites are incomplete.
  exit /b 1
)

echo Result: desktop prerequisites look ready.
exit /b 0

:CheckMsvcTools
where cl >nul 2>nul
if errorlevel 1 goto TryLoadMsvcTools
where link >nul 2>nul
if errorlevel 1 goto TryLoadMsvcTools
cl 2>&1 | findstr /C:"Version"
echo link.exe found.
exit /b 0

:TryLoadMsvcTools
echo cl.exe or link.exe was not found on PATH.
echo Trying common Visual Studio developer shell locations...
call :LoadMsvcToolsWithVswhere
if not errorlevel 1 goto RecheckMsvcTools
call :LoadVsDevCmd "%ProgramFiles%\Microsoft Visual Studio\2026\Enterprise\Common7\Tools\VsDevCmd.bat"
if not errorlevel 1 goto RecheckMsvcTools
call :LoadVsDevCmd "%ProgramFiles%\Microsoft Visual Studio\2026\BuildTools\Common7\Tools\VsDevCmd.bat"
if not errorlevel 1 goto RecheckMsvcTools
call :LoadVsDevCmd "%ProgramFiles%\Microsoft Visual Studio\2026\Community\Common7\Tools\VsDevCmd.bat"
if not errorlevel 1 goto RecheckMsvcTools
call :LoadVsDevCmd "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"
if not errorlevel 1 goto RecheckMsvcTools
call :LoadVsDevCmd "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"
if not errorlevel 1 goto RecheckMsvcTools
call :LoadVsDevCmd "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat"
if not errorlevel 1 goto RecheckMsvcTools
call :LoadVsDevCmd "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"
if not errorlevel 1 goto RecheckMsvcTools
call :LoadVsDevCmd "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"
if not errorlevel 1 goto RecheckMsvcTools
goto MsvcToolsMissing

:LoadMsvcToolsWithVswhere
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" exit /b 1
for /f "usebackq tokens=*" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS_INSTALL=%%I"
if not defined VS_INSTALL exit /b 1
call :LoadVsDevCmd "%VS_INSTALL%\Common7\Tools\VsDevCmd.bat"
exit /b %errorlevel%

:RecheckMsvcTools
where cl >nul 2>nul
if errorlevel 1 goto MsvcToolsMissing
where link >nul 2>nul
if errorlevel 1 goto MsvcToolsMissing
cl 2>&1 | findstr /C:"Version"
echo link.exe found.
exit /b 0

:LoadVsDevCmd
if exist "%~1" (
  echo Loading: "%~1"
  call "%~1" -arch=x64 -host_arch=x64 >nul
  exit /b 0
)
exit /b 1

:MsvcToolsMissing
echo ERROR: cl.exe was not found.
echo ERROR: link.exe was not found.
exit /b 1
