# Backend Exe Packaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package the FastAPI backend as a Windows executable so customers do not need a local Python installation.

**Architecture:** Add a small desktop runtime helper that prepares desktop data paths before importing the FastAPI app. Add a `desktop_server.py` entrypoint for PyInstaller and a Windows packaging script that builds `backend\dist\KnowBaseBackend.exe`.

**Tech Stack:** FastAPI, Uvicorn, PyInstaller, Windows batch, pytest.

---

### Task 1: Desktop Runtime Defaults

**Files:**
- Create: `backend/app/desktop_runtime.py`
- Test: `backend/tests/test_desktop_runtime.py`

- [ ] **Step 1: Write tests for desktop data defaults**

Verify that `configure_desktop_environment()` creates the configured data directory and sets `DATABASE_URL` plus `UPLOAD_DIR` before app import.

- [ ] **Step 2: Implement runtime helper**

Implement `configure_desktop_environment()` with `KNOWBASE_DATA_DIR` override and `%APPDATA%\KnowBase` fallback.

- [ ] **Step 3: Run focused tests**

Run: `backend\.venv\Scripts\python.exe -m pytest tests\test_desktop_runtime.py -q`

### Task 2: Desktop Backend Entrypoint

**Files:**
- Create: `backend/desktop_server.py`

- [ ] **Step 1: Add PyInstaller entrypoint**

Call `configure_desktop_environment()` before importing `app.main`.

- [ ] **Step 2: Run import check**

Run: `backend\.venv\Scripts\python.exe -c "import desktop_server; print('ok')"`

### Task 3: Packaging Script and Dependency

**Files:**
- Modify: `backend/pyproject.toml`
- Create: `package-backend.bat`

- [ ] **Step 1: Add packaging optional dependency**

Add a `packaging` optional dependency group containing PyInstaller.

- [ ] **Step 2: Add package script**

Create `package-backend.bat` to install packaging dependencies into `backend\.venv` and run PyInstaller from the backend directory.

### Task 4: Build and Verify Executable

**Files:**
- Generated only: `backend\dist\KnowBaseBackend.exe`

- [ ] **Step 1: Build executable**

Run: `package-backend.bat`

- [ ] **Step 2: Start executable**

Run the generated executable with `KNOWBASE_DATA_DIR` pointing to `backend\data\desktop-test` and a non-default port.

- [ ] **Step 3: Verify health endpoint**

Request `http://127.0.0.1:<port>/api/health` and expect `{"status":"ok"}`.

### Task 5: Documentation and Verification

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Document backend exe packaging**

Add the packaging command and clarify that this is not yet the final customer installer.

- [ ] **Step 2: Run full verification**

Run backend tests and frontend build.

- [ ] **Step 3: Commit and push**

Commit and push the verified backend packaging foundation.
