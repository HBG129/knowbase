# KnowBase

[![CI](https://github.com/HBG129/knowbase/actions/workflows/ci.yml/badge.svg)](https://github.com/HBG129/knowbase/actions/workflows/ci.yml)

Private AI knowledge workspace for local documents.

KnowBase turns PDFs, Word documents, Markdown notes, text files, and CSVs into searchable knowledge bases with cited AI answers. It is being built as a desktop-first product: a focused local knowledge app, not a generic chat website.

## Product Status

| Area | Status |
| --- | --- |
| Web app | Usable for local development |
| Backend API | Working |
| Backend executable | Working with PyInstaller |
| Desktop shell | Tauri foundation in progress |
| Customer installer | Not released yet |

The current repository is ready for development and packaging work. It is not yet a finished customer installer.

## Why KnowBase

Most AI chat tools make you bring context every time. KnowBase is designed around persistent document knowledge:

- Upload documents into separate knowledge bases.
- Ask questions against selected knowledge bases.
- Get cited answers instead of unsupported free-form replies.
- Keep conversation history tied to the knowledge base.
- Move toward a Windows desktop app customers can install without Python or Node.js.

## Features

- Private knowledge bases for local documents
- PDF, Word, Markdown, TXT, and CSV upload support
- Document ingestion, chunking, and semantic retrieval
- Streaming AI chat with source citations
- Conversation history per knowledge base
- Account registration and JWT login
- Role-aware knowledge base access
- App-style dashboard with first-run guidance
- Recent conversation shortcuts
- Dynamic chat input states based on document readiness
- In-app destructive action confirmations
- Light and dark theme support
- Packaged backend executable foundation for desktop distribution

## Desktop App Roadmap

KnowBase is being prepared for customers who should be able to install and run the app without setting up a development environment.

1. Backend executable with PyInstaller
2. Tauri desktop shell foundation
3. Desktop shell starts and stops the backend automatically
4. Windows installer
5. App icon, signing, update flow, and release packaging

Current milestone: the backend executable is buildable, and the Tauri shell now includes the first backend process startup/shutdown foundation.

## Quick Start

### For users

A customer installer is not available yet. The app is still in desktop packaging work.

When a customer installer is available, the target experience is:

- Install and launch KnowBase without Python, Node.js, Rust, or Git.
- Register an account inside the app.
- Create a knowledge base and upload documents.
- Add a personal LLM API key from the sidebar `Set API Key` action if the installer does not include a system fallback key.
- Ask questions after at least one document has finished processing.

Customers should expect to provide:

- Internet access for LLM API calls.
- A supported provider key: Zhipu GLM, DeepSeek, or OpenAI.
- Permission for KnowBase to store local app data under the Windows user profile.

### For developers

On Windows, from the project root:

```powershell
.\start-dev.bat
```

This checks the backend virtual environment, backend imports, Node.js, npm, and frontend dependencies before starting the dev servers.

Frontend:

```text
http://localhost:3000
```

Backend:

```text
http://127.0.0.1:8000
```

## Architecture

```text
KnowBase
├─ frontend/        Next.js 14, React, Tailwind CSS, Zustand
├─ backend/         FastAPI, SQLAlchemy, SQLite, LangChain
├─ desktop path     PyInstaller backend exe, Tauri shell foundation
└─ data/            Local runtime data, ignored by git
```

### Frontend

- Next.js 14
- React 18
- Tailwind CSS
- Zustand
- Radix UI primitives
- lucide-react icons

### Backend

- FastAPI
- SQLAlchemy
- SQLite by default
- LangChain
- PyMuPDF, python-docx, Markdown parsing
- Server-sent events for streaming chat responses

## Local Development

### 1. Environment file

Create `.env` from the example:

```powershell
Copy-Item .env.example .env
```

Set at least:

```env
JWT_SECRET_KEY=replace-with-a-random-secret
ZHIPU_API_KEY=
DEEPSEEK_BASE_URL=https://api.deepseek.com
OPENAI_API_KEY=
```

At least one LLM provider key should be configured for real chat responses.

### 2. Backend

Backend local development expects Python 3.12. Keep the virtual environment inside the project:

```powershell
cd backend
D:\Anaconda\python.exe -m venv .venv
.\.venv\Scripts\python.exe -c "import subprocess, sys, tomllib; p=tomllib.load(open('pyproject.toml','rb'))['project']; deps=p['dependencies']+p['optional-dependencies']['dev']; subprocess.check_call([sys.executable,'-m','pip','install',*deps])"
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

Do not repoint an existing `.venv` to another Python install. If it points to a missing interpreter, delete and recreate `backend\.venv` with a working Python 3.12 interpreter.

### 3. Frontend

```powershell
cd frontend
npm install
npm run dev
```

## Backend Executable

Build the backend executable:

```powershell
.\package-backend.bat
```

Output:

```text
backend\dist\KnowBaseBackend.exe
```

The packaged backend stores desktop runtime data under `%APPDATA%\KnowBase` by default. For testing, set `KNOWBASE_DATA_DIR` before starting the executable.

Example health-check run:

```powershell
$env:KNOWBASE_DATA_DIR = "D:\Codex_AI_Workspace\knowbase\backend\data\desktop-test"
$env:KNOWBASE_BACKEND_PORT = "8765"
.\backend\dist\KnowBaseBackend.exe
```

Then check:

```text
http://127.0.0.1:8765/api/health
```

Expected response:

```json
{"status":"ok"}
```

## Tauri Desktop Shell

The repository includes the first Tauri shell foundation under:

```text
frontend\src-tauri
```

The local Rust toolchain used during development was installed under:

```text
D:\Codex_AI_Workspace\.tools\rustup
D:\Codex_AI_Workspace\.tools\cargo
```

To use it in a terminal session:

```powershell
.\setup-rust-env.bat
```

To check the desktop packaging prerequisites from the project root:

```powershell
.\check-desktop-prereqs.bat
```

If desktop prerequisites fail, see:

```text
docs\desktop-build-troubleshooting.md
```

Before publishing a customer installer, use:

```text
docs\release-readiness-checklist.md
```

To run the desktop packaging pipeline from one entry point:

```powershell
.\package-desktop.bat
```

The packaging pipeline checks desktop prerequisites first, then builds the backend executable, then runs the Tauri build.

Windows Tauri compilation also requires Microsoft C++ Build Tools. The prerequisite check tries to load common Visual Studio developer shell locations automatically. If `cl.exe` or `link.exe` is still not available, install Microsoft C++ Build Tools and select the `Desktop development with C++` workload before running a full Tauri build. See the official Tauri Windows prerequisites: <https://v2.tauri.app/start/prerequisites/>.

Current local Rust verification:

```text
rustc 1.96.0
cargo 1.96.0
cargo metadata: passed
backend runtime path tests: metadata check passed
cargo check: blocked because link.exe is missing
```

The Visual Studio Build Tools bootstrapper was attempted, but it failed while downloading `vs_installer.opc` due to certificate/network errors from the installer. Install Microsoft C++ Build Tools manually if the automated installer fails on this machine.

Development commands:

```powershell
cd frontend
npm run tauri:dev
npm run tauri:build
```

Release packaging command:

```powershell
.\package-desktop.bat
```

The current Tauri shell can attempt to start `KnowBaseBackend.exe` from an explicit `KNOWBASE_BACKEND_EXE` path, the packaged resource directory, the packaged app directory, or `backend\dist` during development. The Tauri config already declares `backend\dist\KnowBaseBackend.exe` as a bundle resource. The Windows installer, app icon, signing, and update flow are still planned.

## Docker Services

The included `docker-compose.yml` can start PostgreSQL with pgvector, Redis, MinIO, backend, and frontend:

```powershell
docker compose up --build
```

The default local setup uses SQLite and does not require Docker.

## Verification

GitHub Actions runs CI on pushes and pull requests to `main`:

- frontend build with Node 20
- backend tests with Python 3.12

Frontend build:

```powershell
cd frontend
npm run build
```

Backend tests:

```powershell
cd backend
.\.venv\Scripts\python.exe -m pytest tests -q
```

Stable Windows backend test command:

```powershell
cd backend
$tmp = "D:\Codex_AI_Workspace\knowbase\backend\data\pytest-tmp"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$env:TEMP = $tmp
$env:TMP = $tmp
.\.venv\Scripts\python.exe -m pytest tests -q --basetemp $tmp -p no:cacheprovider
```

Recent local verification:

- Backend tests: 42 passed
- Frontend production build: passed
- Backend executable health check: `{"status":"ok"}`
- Rust toolchain: installed under `D:\Codex_AI_Workspace\.tools`
- Desktop prerequisite check: available through `.\check-desktop-prereqs.bat`
- Desktop packaging pipeline: available through `.\package-desktop.bat`
- Tauri backend runtime path check: passed with `rustc --test --emit=metadata`

## Repository Hygiene

- `.gitattributes` keeps source files on LF and Windows batch files on CRLF.
- Batch scripts use ASCII output where possible to avoid console mojibake.
- Packaging scripts route pip, npm, and PyInstaller caches through `D:\Codex_AI_Workspace\.tools` when possible.
- Runtime data, uploaded files, local databases, `.env`, virtual environments, PyInstaller output, `node_modules`, and Next.js build output are ignored by git.

## Security Notes

- Do not commit `.env`, uploaded files, local database files, or API keys.
- Rotate `JWT_SECRET_KEY` before production deployment.
- Customers still need their own LLM API key unless a hosted model service is added later.
- Use production-grade database, object storage, and CORS settings before public exposure.
