# KnowBase Project Plan

KnowBase is a local-first AI knowledge and data workspace. The project combines a desktop RAG knowledge base with a CSV data analysis agent so a Windows user can ask cited questions over private documents and run structured analysis over uploaded CSV files without installing developer tools.

## Product Positioning

Target user:

- portfolio reviewers and interviewers evaluating practical AI application engineering,
- individual Windows users testing a local knowledge base,
- small beta testers who can accept clear pre-release limitations.

Core promise:

```text
Install KnowBase, configure an LLM API key, upload documents or CSV files, ask questions, inspect citations or generated SQL, and keep data local by default.
```

## Current Release Goal

KnowBase is moving toward a customer-installable Windows desktop release.

Release target:

```text
A customer can install KnowBase, launch it, create an account, configure an API key, create a knowledge base, upload documents and CSV files, ask cited questions, run CSV analysis, and close the app without installing Python, Node.js, Rust, or Git.
```

## Differentiators

- Desktop-first RAG workflow with local file storage.
- Cited answers over uploaded PDF, Word, Markdown, TXT, and CSV documents.
- CSV Analysis Agent that profiles uploaded CSV files, asks an LLM for read-only DuckDB SQL, validates the SQL, executes it locally, and stores analysis history.
- Lightweight chart rendering without adding a charting dependency.
- Release workflow with backend packaging, desktop artifact checks, support tools, installer validation docs, and preflight scripts.
- API key storage through Windows Credential Manager in packaged desktop mode, with encrypted database fallback outside desktop mode.

## Active Workstreams

1. Customer-installable desktop packaging
   - Keep `backend\dist\KnowBaseBackend.exe` buildable.
   - Keep Tauri bundle resources and NSIS installer hooks valid.
   - Keep packaged backend health checks scriptable.

2. Knowledge base RAG quality
   - Preserve upload, ingestion, retrieval, citation, and conversation history behavior.
   - Keep missing API key and document readiness states understandable.

3. CSV Analysis Agent
   - Only analyze completed CSV documents in the current knowledge base.
   - Keep SQL read-only and scoped to the registered `dataset` relation.
   - Reject file access, DDL, writes, extension loading, generated table functions, and dataset relation shadowing.
   - Preserve useful results when summary generation fails after SQL execution.
   - Store successful and failed analysis runs independently from chat history.

4. Release readiness
   - Keep release preflight green.
   - Frontend production dependency audit is release-clean on Next.js 15.5.20 with Next's bundled PostCSS overridden to 8.5.10; keep the audit gate green.
   - Keep support and validation docs current.
   - Record signature policy evidence in the release validation issue: valid signer details, or unsigned approver, approval date, and exact release-notes disclosure.
   - Keep generated smoke-test files out of the git working tree.

## Current Blockers

- Local Tauri installer build on this machine is blocked until Microsoft C++ Build Tools provides `cl.exe` and `link.exe`.
- Public customer release still requires clean-machine validation.
- Public customer release needs a valid code signature, or explicit unsigned approval evidence plus a clear unsigned disclosure in the release notes.

## Required Verification Gates

Run the checks that match the changed area:

```powershell
cd backend
.\.venv\Scripts\python.exe -m pytest
cd ..
cd frontend
npm run build
npm audit --omit=dev --audit-level=high
cd ..
.\scripts\check-release-preflight.ps1 -SkipGitStatus
.\scripts\check-packaged-backend-health.ps1
```

For a full local desktop release candidate, also run:

```powershell
.\check-desktop-prereqs.bat
.\package-desktop.bat
.\scripts\check-desktop-artifacts.ps1
```

If `cl.exe` or `link.exe` is missing, stop and use `docs\desktop-build-troubleshooting.md` or the GitHub Actions desktop packaging workflow.

## Engineering Rules For Future Agents

- Preserve user work in the dirty tree. Do not revert unrelated changes.
- Prefer surgical edits that directly support the current release goal.
- Add or update tests before behavior changes when practical.
- Keep generated artifacts, smoke-test data, caches, and temporary files outside the tracked working tree.
- Prefer `D:` for non-essential generated files, caches, tools, and artifacts on this machine when practical.
- Do not weaken SQL safety checks for the Analysis Agent to make a test pass.
- Treat high or critical production dependency advisories as release-blocking; do not waive them silently.
- Do not publish or describe KnowBase as customer-release ready until the release readiness checklist passes on a clean Windows machine.

## Non-Goals For The Current Release

- Hosted SaaS deployment.
- Enterprise SSO.
- Billing.
- Cloud document synchronization.
- Multi-tenant administration.
- Excel analysis support.
- Scheduled reports.
