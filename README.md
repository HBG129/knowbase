# KnowBase

KnowBase is a private AI knowledge-base app for uploading documents, searching them semantically, and asking questions with source citations.

The current product direction is an app-like knowledge workspace rather than a marketing website: a dashboard, knowledge bases, document ingestion, cited chat, and clear first-run guidance.

## Features

- Account registration and login with JWT authentication
- Knowledge base creation and management
- Document upload for PDF, Word, Markdown, TXT, and CSV files
- Document ingestion with chunking and retrieval
- Streaming AI chat with citations
- Conversation history per knowledge base
- App-style dashboard with recent conversation shortcuts
- Dynamic chat input states based on document readiness
- In-app destructive action confirmations
- Light and dark theme support

## Tech stack

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
- SQLite by default, PostgreSQL supported through Docker
- LangChain
- PyMuPDF, python-docx, Markdown parsing
- Server-sent events for streaming chat responses

## Project structure

```text
knowbase/
  backend/                 FastAPI app, models, services, API routes
  frontend/                Next.js app
  docs/superpowers/        Design and implementation notes
  data/                    Local runtime data, ignored by git
  docker-compose.yml       Optional PostgreSQL, Redis, MinIO stack
  start-dev.bat            Dev launcher with hot reload
  start.bat                Existing app launcher
```

## Local setup

### 1. Create environment file

Copy the example file:

```powershell
Copy-Item .env.example .env
```

Edit `.env` and set at least:

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

Frontend runs at:

```text
http://localhost:3000
```

Backend runs at:

```text
http://127.0.0.1:8000
```

### 4. One-click dev startup on Windows

From the project root:

```powershell
.\start-dev.bat
```

This checks the backend virtual environment, backend imports, Node.js, npm, and frontend dependencies before starting servers. It prints the required fix commands when something is missing; it does not install or download dependencies automatically.

## Docker services

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

This avoids Windows permission issues in the default pytest temp/cache paths.

Recent local verification:

- Frontend production build passed.
- Backend test suite passed with 40 tests.

## Desktop packaging

KnowBase is being prepared as a customer-installable desktop app. The first packaging step is the backend executable:

```powershell
.\package-backend.bat
```

This creates:

```text
backend\dist\KnowBaseBackend.exe
```

The packaged backend stores desktop runtime data under `%APPDATA%\KnowBase` by default. For testing, set `KNOWBASE_DATA_DIR` before starting the executable.

This backend executable is not yet the final customer installer. Customers still need a desktop shell and installer, planned next with Tauri.

## Repository hygiene

- `.gitattributes` keeps source files on LF and Windows batch files on CRLF.
- Batch scripts use ASCII output where possible to avoid console mojibake.
- Runtime data, uploaded files, local databases, `.env`, virtual environments, PyInstaller output, `node_modules`, and Next.js build output are ignored by git.

## Recent product polish

- Reworked the home page into an app dashboard.
- Added first-run activation guidance.
- Added recent conversation shortcuts.
- Added supported file type indicators to the upload area.
- Added chat input copy based on document readiness.
- Replaced browser `confirm()` prompts with in-app confirmations.
- Added `start-dev.bat` for development mode.

## Roadmap

- Package as a desktop app with Tauri or Electron.
- Add knowledge base share links with scoped permissions.
- Add OAuth login.
- Add reranker support for retrieval quality.
- Add richer document status and ingestion diagnostics.

## Security notes

- Do not commit `.env`, uploaded files, local database files, or API keys.
- Rotate `JWT_SECRET_KEY` before production deployment.
- Use production-grade database, object storage, and CORS settings before public exposure.
