# KnowBase

[![CI](https://github.com/HBG129/knowbase/actions/workflows/ci.yml/badge.svg)](https://github.com/HBG129/knowbase/actions/workflows/ci.yml)
[![Desktop Package](https://github.com/HBG129/knowbase/actions/workflows/desktop-package.yml/badge.svg)](https://github.com/HBG129/knowbase/actions/workflows/desktop-package.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-pre--release-orange.svg)](docs/project-status.md)

**A local-first AI knowledge and data workspace for Windows.**

KnowBase combines two first-class workflows in one desktop product: an
enterprise-style knowledge-base RAG assistant for cited answers over private
documents, and a CSV Analysis Agent that turns natural-language questions into
guarded, read-only DuckDB SQL, tables, charts, and business insights.

Files and application data stay local by default. Only the question, relevant
document excerpts, or analysis context needed for a request are sent to the LLM
provider selected by the user.

> **Project status:** KnowBase is actively maintained and preparing its first
> public release. The current Windows release candidate has passed CI,
> clean-machine installation, offline runtime, cited RAG, CSV Analysis,
> shutdown, and uninstall validation. The installer is not yet publicly
> released; code signing or an explicitly approved unsigned-release policy is
> still required. See [Project Status](docs/project-status.md).

## Why KnowBase

Many AI tools either answer questions over documents or analyze structured
data. KnowBase keeps both workflows together so a user can move from source
material to evidence-backed answers and from CSV data to inspectable analysis
without installing Python, Node.js, Rust, Git, or a separate database.

| Knowledge-base RAG | CSV Analysis Agent |
| --- | --- |
| Upload PDF, Word, Markdown, TXT, and CSV files | Preview and profile completed CSV datasets |
| Organize private documents into separate knowledge bases | Ask questions in natural language |
| Stream grounded answers with source citations | Generate and display guarded read-only DuckDB SQL |
| Keep conversations tied to their knowledge base | Review result tables, charts, summaries, and insights |
| Control access with account and role-aware permissions | Restore runs from an independent analysis history |

## Highlights

- **Local-first Windows desktop:** Tauri shell with a packaged FastAPI backend,
  local SQLite data, and an app-local WebView2 runtime.
- **Cited RAG:** ingestion, chunking, semantic retrieval, streaming answers, and
  traceable citations for supported documents.
- **Safe structured analysis:** the Analysis Agent accepts only a single
  read-only `SELECT` against the registered `dataset` relation, rejects unsafe
  SQL and external access, and executes queries in a resource-bounded worker.
- **Inspectable output:** users can see the generated SQL, result rows, chart,
  summary, insights, and prior successful or failed analysis runs.
- **Provider choice:** supports Zhipu GLM, DeepSeek, and OpenAI-compatible
  configuration through user-provided API keys.
- **Chinese and English UI:** core authentication, knowledge-base, cited chat,
  settings, and Analysis workflows are localized.
- **Release engineering:** locked dependencies, CI audits, PyInstaller and
  Tauri/NSIS packaging, release manifests/SBOMs, provenance attestations,
  release preflight, artifact verification, and customer support scripts.

## Verified Release Evidence

The repository records reproducible engineering and release evidence rather
than presenting KnowBase as a one-off demo:

- **158 backend tests** in the latest confirmed CI run.
- Frontend production build and Python/Node production dependency audits.
- Automated packaged-backend health and Analysis API contract checks.
- Tauri runtime tests and Windows installer artifact verification.
- Offline Windows Sandbox installation on a machine without development tools.
- Real-provider validation covering Chinese cited RAG and guarded CSV Analysis.
- Dynamic loopback-port fallback, graceful process cleanup, uninstall, and
  customer-data preservation checks.

Exact run identifiers, artifact hashes, limitations, and remaining release
gates are tracked in [Project Status](docs/project-status.md) and the
[release candidate record](docs/release-candidate-v0.1.0-rc.1.md).

## Architecture

```text
KnowBase Desktop
|-- Next.js 15 + React 18 + Tailwind CSS
|   |-- knowledge-base and document workflows
|   |-- streaming cited chat
|   `-- CSV Analysis workbench
|-- Tauri 2 Windows shell
|   `-- lifecycle, authenticated dynamic loopback backend, NSIS installer
`-- FastAPI + SQLAlchemy backend
    |-- document ingestion, embeddings, retrieval, and citations
    |-- resource-bounded DuckDB CSV analysis
    |-- SQLite application and history storage
    `-- provider credentials and API integrations
```

See [Architecture](docs/architecture.md) for the request flows, storage model,
desktop lifecycle, and security boundaries.

## Current Release Status

| Area | Current state |
| --- | --- |
| Knowledge-base RAG | Implemented and validated with real-provider citations |
| CSV Analysis Agent | Implemented and validated with guarded SQL and saved history |
| Windows packaging | CI produces a Tauri/NSIS installer artifact |
| Clean-machine validation | Passed in offline Windows Sandbox |
| Public GitHub Release | Not published yet |
| Remaining gate | Valid code signature or approved unsigned-release disclosure |

The controlled tester target is `v0.1.0-rc.1`; the general-availability target
is `v0.1.0` after all release gates pass. Follow the
[release-readiness checklist](docs/release-readiness-checklist.md) for the
authoritative gate sequence.

## Quick Start

### Windows users

A public customer installer is not available yet. Do not treat CI artifacts as
a supported release unless you are participating in controlled validation.

When the first release is published, the intended user flow is:

1. Install and launch KnowBase without a development toolchain.
2. Register a local account and add a supported provider API key.
3. Create a knowledge base and upload documents or CSV files.
4. Ask cited questions in Chat, or open **Analysis** to inspect and query CSV
   data.

See the [Customer Quick Start](docs/customer-quick-start.md),
[Data and Privacy](docs/customer-data-and-privacy.md), and
[Known Limitations](docs/known-limitations.md).

Windows repository paths: `docs\customer-quick-start.md` and
`docs\customer-data-and-privacy.md`.

### Developers

Prerequisites:

- Windows 10 or 11
- Python 3.12
- Node.js 20 and npm
- Rust and Microsoft C++ Build Tools only for local desktop packaging

Clone the repository and create the local environment file:

```powershell
git clone https://github.com/HBG129/knowbase.git
cd knowbase
Copy-Item .env.example .env
```

Create the locked backend environment and install dependencies:

```powershell
cd backend
uv sync --locked --extra dev --no-install-project --python 3.12
cd ..
```

Install frontend dependencies and start both development servers:

```powershell
cd frontend
npm install
cd ..
.\start-dev.bat
```

The frontend runs at `http://localhost:3000`; the backend uses
`http://127.0.0.1:8000` by default.

Configure at least one provider key through the application before running
real chat, embeddings, or analysis. Never commit `.env` or provider keys.

## Verification

Run the checks that match your change.

Backend tests and dependency audit:

```powershell
cd backend
.\.venv\Scripts\python.exe -m pytest
.\.venv\Scripts\python.exe -m pip_audit --local --strict
```

Frontend build and production dependency audit:

```powershell
cd frontend
npm run build
npm audit --omit=dev --audit-level=high
```

Repository and release gates:

```powershell
.\scripts\check-release-preflight.ps1 -SkipGitStatus
.\scripts\check-packaged-backend-health.ps1
```

Full desktop packaging requires the prerequisites documented in
[Desktop Build Troubleshooting](docs/desktop-build-troubleshooting.md):

```powershell
.\check-desktop-prereqs.bat
.\package-desktop.bat
.\scripts\check-desktop-artifacts.ps1
```

## Documentation

- [Documentation index](docs/README.md)
- [Architecture](docs/architecture.md)
- [Project status and verification evidence](docs/project-status.md)
- [Roadmap](docs/roadmap.md)
- [Release process](docs/release-process.md)
- [Security policy](SECURITY.md)
- [Changelog](CHANGELOG.md)

## Contributing

Issues, focused pull requests, documentation improvements, and reproducible
validation reports are welcome. Before contributing, read
[CONTRIBUTING.md](CONTRIBUTING.md) and the
[Code of Conduct](CODE_OF_CONDUCT.md).

Please keep changes surgical, update documentation when behavior changes, and
run the checks relevant to the modified area. Structured templates are
available for bug reports, feature requests, beta feedback, releases, and pull
requests.

## Security and Privacy

Do not publish API keys, private documents, local databases, credential-store
records, or support bundles containing sensitive data. Report vulnerabilities
according to [SECURITY.md](SECURITY.md).

KnowBase is local-first, not fully offline: provider-backed chat, embeddings,
and analysis send the minimum request context needed to the configured provider.
Review the [data and privacy notes](docs/customer-data-and-privacy.md) before
using sensitive material.

## License

Copyright 2026 HBG129.

Licensed under the [Apache License 2.0](LICENSE).
