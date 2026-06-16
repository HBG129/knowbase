# Desktop Packaging Design

## Goal

KnowBase should become a customer-installable Windows app. A customer should not need to install Python, Node.js, npm packages, or Python packages to use the app.

## Scope

This design splits desktop packaging into phases:

1. Package the FastAPI backend as a Windows executable.
2. Add a desktop shell with Tauri.
3. Make the desktop shell start and stop the backend process.
4. Build a Windows installer.
5. Add signing, update, and customer distribution polish.

The first implementation phase only packages the backend. It does not install Rust, Tauri, Visual Studio Build Tools, or create the final customer installer.

## Recommended Architecture

Use Tauri for the desktop shell and PyInstaller for the Python backend.

The final app should contain:

- a bundled web frontend served inside a desktop window,
- a bundled backend executable started by the desktop shell,
- local app data under the user's app data directory,
- a first-run configuration flow for model API keys.

## Backend Runtime

The backend executable must be able to run without a source checkout. It should set safe desktop defaults before importing the FastAPI app:

- `DATABASE_URL` points to a SQLite database in the desktop data directory.
- `UPLOAD_DIR` points to an uploads folder in the desktop data directory.
- required folders are created on startup.

The desktop data directory defaults to:

```text
%APPDATA%\KnowBase
```

During development and tests, `KNOWBASE_DATA_DIR` can override that location.

## Customer Impact

After all phases are complete, customers can install and open KnowBase without setting up Python or Node.js. They will still need to configure their own LLM API key unless KnowBase later provides a hosted model service.

## Non-goals

- No cloud account system in this phase.
- No auto-update in this phase.
- No code signing in this phase.
- No bundled API keys.
