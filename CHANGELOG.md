# Changelog

All notable changes to KnowBase are tracked here.

This project is still pre-release. Version numbers below describe repository milestones, not customer-ready installer releases.

## Unreleased

### Added

- CSV Analysis Agent with preview/profile, guarded read-only DuckDB SQL, charts, summaries, insights, and independent history.
- Complete Chinese and English product localization with typed translation keys and CI coverage enforcement.
- Windows desktop packaging with Tauri, PyInstaller, NSIS lifecycle hooks, packaged-backend health checks, and artifact verification.
- Branded Windows app icon, installer metadata, and release signature policy checks.
- Customer quick start, privacy notes, release process, support runbook, and architecture documentation.
- Dry-run-first backup, restore, and local-data removal tools plus non-sensitive support and installed-app reports.
- Synthetic demo data for safe screenshots, release validation, and interview walkthroughs.
- GitHub issue templates, pull request template, Dependabot configuration, and release notes categorization.

### Changed

- README now presents KnowBase as a desktop-first AI knowledge workspace.
- Release documentation now separates release notes, readiness checks, and demo asset guidance.
- Packaged API keys use Windows Credential Manager; non-desktop fallback storage is encrypted.
- GitHub Actions and Miniconda setup use Node 24-compatible action runtimes.
- Windows NSIS packages now embed the offline WebView2 Runtime instead of depending on a successful first-run download.
- Next.js resolves `sharp` to patched version `0.35.3` after the upstream libvips security advisory.
- Repository text normalization now includes `.txt`, `.csv`, and `.gitattributes`.

### Known Limitations

- Windows installer artifact is produced by CI, but it is not publicly released yet.
- Local Tauri packaging still requires Microsoft C++ Build Tools.
- The offline-WebView2 replacement installer still requires clean-machine validation.
- App signing and auto-update are not configured yet.

## 0.1.0-pre

Initial pre-release development milestone:

- FastAPI backend for authentication, knowledge bases, documents, conversations, and chat.
- LangChain-based RAG flow with document parsing, chunking, retrieval, and cited answers.
- Next.js and React frontend with dashboard, upload flow, chat UI, recent conversations, and guided empty states.
- Local SQLite development storage.
- Backend executable packaging foundation.
