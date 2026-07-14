# KnowBase Architecture

KnowBase is a desktop-first AI knowledge and data workspace. The product goal is simple: let a customer install a Windows app, upload private documents or CSV files, ask cited questions, and run local CSV analysis without installing Python, Node.js, Rust, or Git.

This document explains how the current system is organized and where the desktop packaging work fits.

## Runtime Modes

### Local development

Local development runs the frontend and backend as separate processes:

```text
Browser -> Next.js frontend -> FastAPI backend -> SQLite / local files / LLM provider
```

Default endpoints:

```text
Frontend: http://localhost:3000
Backend:  http://127.0.0.1:8000
```

The standard launcher is:

```powershell
.\start-dev.bat
```

### Desktop runtime

The target desktop runtime wraps the frontend in Tauri and starts the packaged backend executable automatically:

```text
Tauri shell -> bundled KnowBaseBackend.exe -> local app data -> LLM provider
```

The packaged backend stores runtime data under the Windows user profile by default:

```text
%APPDATA%\KnowBase
```

During development, the backend executable is built into:

```text
backend\dist\KnowBaseBackend.exe
```

### CI packaging

The repository includes a manual GitHub Actions workflow for desktop packaging:

```text
.github\workflows\desktop-package.yml
```

Use it when local desktop packaging is blocked by missing Microsoft C++ Build Tools.

The workflow uploads two short-lived artifacts:

```text
KnowBaseBackend-<run number>
KnowBaseDesktop-Windows-<run number>
```

Before upload, `scripts\check-desktop-artifacts.ps1` verifies that both the packaged backend executable and NSIS installer exist.

## Components

```text
KnowBase
+-- frontend/          Next.js, React, Tailwind CSS, Zustand, Radix UI
+-- frontend/src-tauri Tauri desktop shell and backend process lifecycle
+-- backend/           FastAPI, SQLAlchemy, SQLite, LangChain services
+-- docs/              customer, release, support, and architecture docs
+-- .github/           CI, packaging workflow, issue and PR templates
```

### Frontend

The frontend provides the app shell, authentication screens, knowledge base management, document upload flow, chat interface, CSV Analysis tab, recent conversations, empty states, and API key prompts.

Key responsibilities:

- render the customer-facing workspace
- call backend APIs
- stream chat responses
- display citations and document readiness states
- preview CSV datasets, analysis results, generated SQL, summaries, charts, and analysis history
- keep destructive actions behind in-app confirmations

### Backend

The backend owns authentication, data persistence, document ingestion, retrieval, CSV analysis, and LLM orchestration.

Key responsibilities:

- register and authenticate users with JWT
- manage knowledge bases, documents, conversations, and messages
- parse uploaded PDF, Word, Markdown, TXT, and CSV files
- chunk and embed document content
- retrieve relevant context for a chat request
- profile completed CSV documents for structured analysis
- validate LLM-generated SQL before DuckDB execution
- save analysis history independently from chat history
- call the configured LLM provider
- stream model responses back to the frontend

### Desktop shell

The Tauri shell is responsible for turning the web app into a Windows desktop app and managing the local backend process.

Key responsibilities:

- locate `KnowBaseBackend.exe`
- start the backend when the desktop app launches
- stop the backend when the desktop app exits
- load the frontend inside the desktop window
- prepare the app for installer packaging

## Data Flow

### Document ingestion

```text
User uploads file
-> frontend sends file to backend
-> backend validates file type
-> backend extracts text
-> backend splits text into chunks
-> backend generates embeddings
-> backend stores document metadata, chunks, and vectors
```

Supported document formats:

- PDF
- Word `.docx`
- Markdown
- TXT
- CSV

### Chat

```text
User asks a question
-> frontend sends message and knowledge base context
-> backend loads conversation and document state
-> backend retrieves relevant chunks
-> backend builds the prompt
-> backend calls the selected LLM provider
-> backend streams the answer
-> frontend renders the answer and citations
-> backend stores the conversation turn
```

The expected product behavior is that users receive cited answers grounded in uploaded documents, not unsupported free-form chat responses.

### CSV Analysis

```text
User opens Analysis tab
-> frontend lists completed CSV datasets for the current knowledge base
-> backend profiles CSV columns and previews rows
-> user asks a natural-language analysis question
-> backend asks the LLM for strict JSON containing a SQL plan
-> backend validates a single read-only SELECT or WITH query
-> DuckDB executes the query against the registered dataset relation
-> backend returns limited rows, chart spec, summary, insights, and run history
-> frontend renders the table, lightweight SVG chart, SQL, summary, and history item
```

The expected product behavior is that CSV analysis stays scoped to completed CSV files the user can already access in the current knowledge base.

## LLM Provider Resolution

KnowBase is designed to support both user-provided keys and system fallback keys.

Resolution order:

1. User-selected provider and user API key.
2. System fallback key from environment configuration.
3. Frontend prompt asking the user to configure an API key.

Current supported provider direction:

- Zhipu GLM
- DeepSeek-compatible endpoint
- OpenAI-compatible endpoint

Do not commit provider keys to the repository.

## Storage

### Development

Local development data is stored under the backend workspace unless overridden by environment variables:

```text
backend\data
```

### Desktop

Desktop runtime data should stay in the Windows user profile:

```text
%APPDATA%\KnowBase
```

Expected data includes:

- SQLite database
- uploaded documents
- extracted document text
- vector data
- logs that do not contain secrets or private document contents

## Packaging Flow

Backend executable:

```powershell
.\package-backend.bat
```

Desktop package:

```powershell
.\package-desktop.bat
```

The desktop packaging script runs the prerequisite check, builds the backend executable, then runs the Tauri build.

Known local blocker:

```text
cl.exe / link.exe missing until Microsoft C++ Build Tools are installed
```

If local packaging is blocked, use the manual GitHub Actions desktop packaging workflow.

## Security Boundaries

KnowBase handles private documents and API keys. Treat these as sensitive by default.

Do not commit:

- `.env`
- API keys
- uploaded documents
- local SQLite databases
- `%APPDATA%\KnowBase`
- generated build outputs

Current release-sensitive areas:

- CSV analysis SQL must remain read-only, single-statement, and scoped to the uploaded dataset relation.
- API key storage should remain backed by Windows Credential Manager in packaged desktop mode, with encrypted database fallback outside desktop mode.
- Logs must not include private document text or tokens.
- Public web deployment requires production CORS, storage, database, and secret-management hardening.

See:

```text
SECURITY.md
docs\customer-data-and-privacy.md
docs\known-limitations.md
```

## Verification Commands

Use the checks that match the changed area.

Frontend:

```powershell
cd frontend
npm run build
```

Backend:

```powershell
cd backend
.\.venv\Scripts\python.exe -m pytest
```

Desktop prerequisites:

```powershell
.\check-desktop-prereqs.bat
```

Desktop packaging:

```powershell
.\package-desktop.bat
```

Docs-only changes should still be checked with git diff and link review before commit.
