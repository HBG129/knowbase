# KnowBase v0.1.0-rc.1 Release Candidate

This document records the selected release target and current validation evidence. It is not approval to publish the installer.

## Version Decision

- Controlled tester candidate: `v0.1.0-rc.1`
- Installed application ProductVersion: `0.1.0`
- General availability target after all release gates pass: `v0.1.0`

## Candidate Scope

- Windows desktop application with bundled FastAPI backend.
- Chinese and English interfaces for the complete customer workflow.
- Local PDF, Word, Markdown, TXT, and CSV knowledge bases.
- RAG answers with source citations and conversation history.
- CSV Analysis workspace with read-only DuckDB queries, charts, summaries, insights, and analysis history.
- Windows Credential Manager API key storage with encrypted fallback storage outside the packaged desktop runtime.
- Customer backup, restore, removal, troubleshooting, and non-sensitive support-report tools.

## Current Evidence

- Validated source commit: `02bfc4d0d5bc1813aad63d2497c759e10f82c724`
- PR CI run `30698708279`: repository checks, Python and frontend production dependency audits, `138` backend tests, and frontend build passed.
- Desktop package run `30698787062`: clean dependency installation, both dependency audits, backend tests, frontend build, pinned WebView2 download and verification, PyInstaller, Tauri/NSIS packaging, packaged-backend health, artifact verification, signature status check, and both artifact uploads passed.
- GitHub artifact: `KnowBaseDesktop-Windows-31`
- GitHub artifact digest: `sha256:c3552cf384dd9c7b9e2374cac343b1da13d6466e2931a1de22ade7532e02237c`
- Installer: `KnowBase_0.1.0_x64-setup.exe`, `310171268` bytes, SHA256 `D84FA9EFBAD460324587F00232BB7E3C791BF3D8C93BAA68473C581F7DA640B7`
- Installer Authenticode status: `NotSigned`
- The candidate pins Next.js `15.5.21`, Next's bundled PostCSS `8.5.18`, and WebView2 Fixed Version Runtime `150.0.4078.99`.
- Local upgrade/install verification passed for shortcuts, bundled backend startup, listener ownership, health response, and process cleanup after closing the desktop window.
- Complete Chinese/English desktop and mobile visual checks passed for the dashboard, knowledge-base, document, chat, and Analysis surfaces.
- Offline Windows Sandbox validation on 2026-08-03 passed for the exact artifact without Python, Node.js, npm, Rust, Cargo, Git, project source code, or network access.
- The Sandbox proved installation, fixed-runtime UI rendering from the app-local `150.0.4078.99` process path, backend health and listener ownership, authentication, knowledge-base creation, Markdown/CSV upload, dataset discovery, CSV profile, WM_CLOSE-equivalent window shutdown, backend cleanup, silent uninstall, and preservation of `%APPDATA%\KnowBase`.
- Real-provider validation on 2026-08-03 passed on the installed exact candidate with synthetic data: Zhipu embedding ingestion, Chinese grounded RAG with two complete citations, CSV Analysis with safe DuckDB SQL, three result rows, bar chart, Chinese summary, insights, analysis-history restore, credential removal, process cleanup, and isolated-data cleanup all passed.

## Blocking Gates

- Obtain a valid code-signing certificate, or record explicit approval for an unsigned tester release and include the exact disclosure in the release notes.

Do not create a public GitHub Release until every blocking gate is resolved and the release validation issue records a `Ready` decision.
