# Changelog

All notable changes to KnowBase are tracked here.

This project is still pre-release. Version numbers below describe repository milestones, not customer-ready installer releases.

## Unreleased

### Added

- Windows desktop packaging foundation with Tauri and PyInstaller.
- Manual GitHub Actions desktop packaging workflow.
- Customer quick start, privacy notes, release process, support runbook, and architecture documentation.
- Synthetic demo data for safe screenshots, release validation, and interview walkthroughs.
- GitHub issue templates, pull request template, Dependabot configuration, and release notes categorization.

### Changed

- README now presents KnowBase as a desktop-first AI knowledge workspace.
- Release documentation now separates release notes, readiness checks, and demo asset guidance.
- Repository text normalization now includes `.txt`, `.csv`, and `.gitattributes`.

### Known Limitations

- Customer installer is not published yet.
- Local Tauri packaging still requires Microsoft C++ Build Tools.
- App signing and auto-update are not configured yet.
- API key storage should move toward OS credential storage before broad customer release.

## 0.1.0-pre

Initial pre-release development milestone:

- FastAPI backend for authentication, knowledge bases, documents, conversations, and chat.
- LangChain-based RAG flow with document parsing, chunking, retrieval, and cited answers.
- Next.js and React frontend with dashboard, upload flow, chat UI, recent conversations, and guided empty states.
- Local SQLite development storage.
- Backend executable packaging foundation.
