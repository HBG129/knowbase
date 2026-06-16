# Dev Launcher Reliability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Windows local development startup fail early with clear guidance when backend or frontend prerequisites are missing.

**Architecture:** Keep the launcher as a single root-level batch script. It validates local prerequisites, starts backend and frontend dev servers in separate windows, and does not install dependencies automatically.

**Tech Stack:** Windows batch, Python 3.12 venv, FastAPI/Uvicorn, Node/npm, Next.js.

---

### Task 1: Harden `start-dev.bat`

**Files:**
- Modify: `start-dev.bat`

- [ ] **Step 1: Add prerequisite checks**

Check for `backend\.venv\Scripts\python.exe`, Python `>=3.12`, importable `fastapi` and `uvicorn`, `frontend\package.json`, `node`, `npm`, and `frontend\node_modules\.bin\next.cmd`.

- [ ] **Step 2: Preserve manual dependency control**

When dependencies are missing, print the exact commands the user should run instead of installing automatically.

- [ ] **Step 3: Start both dev servers**

Start backend with `uvicorn --reload` at `http://127.0.0.1:8000` and frontend with `npm run dev` at `http://localhost:3000`.

### Task 2: Update Local Development Docs

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Document supported Python**

State that backend local development expects Python 3.12 and that the current recommended local venv is project-local under `backend\.venv`.

- [ ] **Step 2: Document dependency install commands**

Add explicit backend and frontend install commands. Keep paths under the project directory on `D:` when following the current workspace layout.

- [ ] **Step 3: Document launcher behavior**

Explain that `start-dev.bat` checks prerequisites and prints remediation commands instead of silently downloading packages.

### Task 3: Verify and Publish

**Files:**
- Verify only unless a command reveals a directly related failure.

- [ ] **Step 1: Run backend tests**

Run the stable Windows backend test command and expect `40 passed`.

- [ ] **Step 2: Run frontend build**

Run `npm run build` in `frontend` and expect a successful production build.

- [ ] **Step 3: Inspect Git diff**

Confirm the changed files are limited to dependency stability, launcher reliability, README, and this plan.

- [ ] **Step 4: Commit and push**

Commit the verified changes and push to `origin/main`.
