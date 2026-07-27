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

- Validated source commit: `1a4c8042eaa4f081989c505006fccf828eb74761`
- PR CI run `30250177575`: repository checks, `126` backend tests, production dependency audit, and frontend build passed.
- Desktop package run `30250261389`: clean dependency installation, audit, backend tests, frontend build, pinned WebView2 download and verification, PyInstaller, Tauri/NSIS packaging, packaged-backend health, artifact verification, signature status check, and both artifact uploads passed.
- GitHub artifact: `KnowBaseDesktop-Windows-28`
- Artifact ZIP SHA256: `37F106F9179E2492DE6445090FFBD024CA4C719DD8848BECE4290E2A24937724`
- Installer: `KnowBase_0.1.0_x64-setup.exe`, `309619211` bytes, SHA256 `690D99CF36E20296FEC94FB8D47626501A06BEBD035347D4F665B76711B5D80E`
- Installer Authenticode status: `NotSigned`
- The candidate pins Next.js `15.5.21`, Next's bundled PostCSS `8.5.18`, and WebView2 Fixed Version Runtime `150.0.4078.99`.
- Local upgrade/install verification passed for shortcuts, bundled backend startup, listener ownership, health response, and process cleanup after closing the desktop window.
- Complete Chinese/English desktop and mobile visual checks passed for the dashboard, knowledge-base, document, chat, and Analysis surfaces.
- Offline Windows Sandbox validation on 2026-07-27 passed for the exact artifact without Python, Node.js, npm, Rust, Cargo, Git, project source code, or network access.
- The Sandbox proved installation, fixed-runtime UI rendering from the app-local `150.0.4078.99` process path, backend health and listener ownership, authentication, knowledge-base creation, Markdown/CSV upload, dataset discovery, CSV profile, WM_CLOSE-equivalent window shutdown, backend cleanup, silent uninstall, and preservation of `%APPDATA%\KnowBase`.

## Blocking Gates

- Confirm real-provider cited chat and natural-language CSV Analysis with the exact candidate artifact.
- Obtain a valid code-signing certificate, or record explicit approval for an unsigned tester release and include the exact disclosure in the release notes.
- Replace the remaining `not tested` clean-machine results with attached validation evidence.

Do not create a public GitHub Release until every blocking gate is resolved and the release validation issue records a `Ready` decision.
