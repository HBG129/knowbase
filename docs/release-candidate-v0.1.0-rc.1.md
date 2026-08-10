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

- Validated source commit: `8611043353e81704944255b7b66d0543185c64af`
- PR CI run `31426401406`: repository checks, Python and frontend production dependency audits, `141` backend tests, and frontend build passed.
- Desktop package run `31426443435`: clean dependency installation, both dependency audits, backend tests, frontend build, standalone Rust desktop-runtime tests, pinned WebView2 download and verification, PyInstaller, Tauri/NSIS packaging, packaged-backend health, artifact verification, signature status check, and both artifact uploads passed.
- GitHub artifact: `KnowBaseDesktop-Windows-36`
- GitHub artifact digest: `sha256:e37038c6283e6d65dff9225238da97d13806a05b769ff8ede759a36c482ea77b`
- Installer: `KnowBase_0.1.0_x64-setup.exe`, `310498339` bytes, SHA256 `A7A8C3C48BF5BDF1967958C57605511D64FFF9061C3B91B6CD916047F69E5685`
- Installer Authenticode status: `NotSigned`
- The candidate pins Next.js `15.5.23`, Next's bundled PostCSS `8.5.26`, Nano ID `3.3.18`, Python security floors `aiohttp>=3.14.3` and `cryptography>=50.0.0`, and WebView2 Fixed Version Runtime `150.0.4078.99`.
- Local upgrade/install verification passed for shortcuts, bundled backend startup, listener ownership, health response, and process cleanup after closing the desktop window.
- Complete Chinese/English desktop and mobile visual checks passed for the dashboard, knowledge-base, document, chat, and Analysis surfaces.
- Offline Windows Sandbox validation on 2026-08-11 passed for the exact artifact without Python, Node.js, npm, Rust, Cargo, Git, project source code, or network access.
- The Sandbox deliberately occupied port `8000`; KnowBase selected `127.0.0.1:49674` and passed installation, fixed-runtime UI rendering from the app-local `150.0.4078.99` process path, backend health and listener ownership, authentication, knowledge-base creation, Markdown/CSV upload, dataset discovery, CSV profile, WM_CLOSE-equivalent window shutdown, backend cleanup, silent uninstall, and preservation of `%APPDATA%\KnowBase`.
- Real-provider validation on 2026-08-11 passed on the installed exact candidate with port `8000` deliberately occupied. KnowBase selected `127.0.0.1:58809`; Zhipu embedding ingestion, Chinese grounded RAG with two complete citations, CSV Analysis with safe DuckDB SQL, three result rows, bar chart, Chinese summary, insights, analysis-history restore, credential removal, process cleanup, and isolated-data cleanup all passed.

## Blocking Gates

- Obtain a valid code-signing certificate, or record explicit approval for an unsigned tester release and include the exact disclosure in the release notes.

Do not create a public GitHub Release until every blocking gate is resolved and the release validation issue records a `Ready` decision.
