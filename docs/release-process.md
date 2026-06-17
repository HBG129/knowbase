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

Do not publish if packaging fails or if the generated bundle is missing.

Alternatively, run the manual GitHub Actions workflow:

```text
Desktop Package
```

This uses a GitHub-hosted Windows runner and can build without relying on the local machine's Visual Studio Build Tools installation.

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
