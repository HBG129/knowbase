# Desktop Build Troubleshooting

This guide covers the Windows desktop packaging path for KnowBase.

## Expected Packaging Flow

From the project root:

```powershell
.\check-desktop-prereqs.bat
.\package-desktop.bat
```

`package-desktop.bat` runs three steps:

1. Check desktop prerequisites.
2. Build the backend executable with PyInstaller.
3. Build the Tauri desktop bundle.

The final desktop output should be created under:

```text
frontend\src-tauri\target\release\bundle
```

## Required Tools

The desktop build requires:

- Node.js and npm
- Rust and Cargo
- Microsoft C++ Build Tools
- Backend executable at `backend\dist\KnowBaseBackend.exe`
- Tauri manifest at `frontend\src-tauri\tauri.conf.json`

The project scripts route local tool caches through:

```text
D:\Codex_AI_Workspace\.tools
```

## Current Known Blocker

If `.\check-desktop-prereqs.bat` reports:

```text
ERROR: cl.exe was not found.
ERROR: link.exe was not found.
```

then the Windows C++ compiler and linker are missing from the current machine.
This blocks the Tauri build even if Node.js, Rust, Cargo, and the backend executable are all working.

Install Microsoft C++ Build Tools and select:

```text
Desktop development with C++
```

Then restart the terminal and run:

```powershell
.\check-desktop-prereqs.bat
```

The script tries to load common Visual Studio developer shell paths automatically, so a normal terminal should work after the tools are installed.

## Visual Studio Installer Certificate Failure

On this machine, the Visual Studio Build Tools bootstrapper failed with exit code `5003`.

The installer log showed:

```text
Certificate is invalid: vs_installer.opc
WinInet error 12057
Error 0x80072f19: Failed to download
```

This is an environment, certificate trust, or network/proxy problem from the Visual Studio installer download path. It is not a KnowBase source-code failure.

Practical recovery options:

1. Install Microsoft C++ Build Tools manually from a browser or Visual Studio Installer.
2. Fix Windows date/time, Windows Update root certificates, proxy, VPN, or SSL inspection settings, then rerun the installer.
3. Build the desktop installer on another Windows machine that already has Microsoft C++ Build Tools installed.

After `cl.exe` and `link.exe` are available, rerun:

```powershell
.\package-desktop.bat
```

## Fast Diagnosis

Run these commands from the project root:

```powershell
.\check-desktop-prereqs.bat
where cl
where link
```

Expected result after MSVC is installed:

```text
cl.exe found through the Visual Studio developer shell
link.exe found
Result: desktop prerequisites look ready.
```

If `where cl` or `where link` still fails after installation, open "Developer PowerShell for VS 2022" once and rerun the prerequisite check from there.
