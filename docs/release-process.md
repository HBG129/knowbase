# Release Process

Use this process when preparing a KnowBase Windows desktop release.

Do not publish a customer installer until `docs\release-readiness-checklist.md` passes.

## 1. Confirm The Build Machine

Run from the repository root:

```powershell
.\check-desktop-prereqs.bat
```

The build machine must have:

- Node.js and npm
- Rust and Cargo
- Microsoft C++ Build Tools with `Desktop development with C++`
- Python 3.12 backend environment
- backend dependencies installed
- frontend dependencies installed

If `cl.exe` or `link.exe` is missing, stop and fix the Visual Studio Build Tools installation first.

## 2. Run Verification

Run backend tests:

```powershell
cd backend
.\.venv\Scripts\python.exe -m pytest tests -q
```

Run frontend build:

```powershell
cd frontend
npm run build
```

Return to the repository root before packaging:

```powershell
cd ..
```

## 3. Build The Desktop Package

Run:

```powershell
.\package-desktop.bat
```

Expected output location:

```text
frontend\src-tauri\target\release\bundle
```

Verify generated artifacts:

```powershell
.\scripts\check-desktop-artifacts.ps1
```

Do not publish if packaging fails, if the generated bundle is missing, or if the artifact check fails.

Alternatively, run the manual GitHub Actions workflow:

```text
Desktop Package
```

This uses a GitHub-hosted Windows runner and can build without relying on the local machine's Visual Studio Build Tools installation.

The same workflow also runs automatically on pushes to `main` when backend, frontend, desktop packaging scripts, or the desktop workflow itself changes.

Expected GitHub Actions artifacts:

```text
KnowBaseBackend-<run number>
KnowBaseDesktop-Windows-<run number>
```

The desktop artifact must include the NSIS installer output from:

```text
frontend\src-tauri\target\release\bundle\nsis
```

If the workflow cannot find the backend executable or NSIS installer, the artifact verification step fails before upload.

After downloading the desktop artifact ZIP, verify it before installation:

```powershell
.\scripts\check-release-artifact.ps1 -ZipPath D:\Codex_AI_Workspace\artifacts\KnowBaseDesktop-Windows-3.zip
```

## 4. Test On A Clean Windows Machine

Install the generated package on a Windows machine or virtual machine without the development toolchain.

The clean machine must not require:

- Python
- Node.js
- Rust
- Git
- project source code

Validate the first-run flow in:

```text
docs\customer-quick-start.md
```

Record the clean-machine result with:

```text
docs\clean-machine-validation.md
```

## 5. Prepare Release Notes

Use the template in:

```text
docs\release-notes-template.md
```

Release notes must include:

- version,
- highlights,
- requirements,
- known limitations,
- verification results,
- installer artifact name.

If the release includes visible UI changes, prepare demo assets using:

```text
docs\demo-assets.md
```

## 6. Publish The GitHub Release

Before publishing:

- confirm the git working tree is clean,
- confirm the release commit is pushed,
- attach the installer artifact,
- include release notes,
- include known limitations.

If code signing is not configured, state that clearly in the release notes.

## 7. Post-Release Checks

After publishing:

- download the release artifact from GitHub,
- install it on a clean Windows machine,
- launch the app,
- configure an API key,
- upload one test document,
- ask one question,
- close the app and confirm the backend exits.

Record the result in the release notes or release issue.
