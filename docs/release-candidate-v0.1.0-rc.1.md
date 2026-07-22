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

- Source commit: `6b3606b0204211f2f89ade5bb13bbb131eb9f11f`
- PR CI run `29639530539`: repository checks, backend tests, and frontend build passed.
- Desktop package run `29639608446`: backend tests, frontend build, PyInstaller, Tauri/NSIS packaging, packaged-backend health, artifact verification, signature status check, and both artifact uploads passed.
- GitHub artifact: `KnowBaseDesktop-Windows-25`
- Artifact ZIP SHA256: `CB59221D736321049AC718F28E6FAC473E5695D00B441AF2A4A8FF0689579015`
- Installer: `KnowBase_0.1.0_x64-setup.exe`
- Installer SHA256: `2B5148882FB19D8139ED0EA239CEF525F24CF7797178748AF702BBA988C610BD`
- Installer Authenticode status: `NotSigned`
- Local upgrade/install verification passed for shortcuts, bundled backend startup, listener ownership, health response, and process cleanup after closing the desktop window.
- Complete Chinese/English desktop and mobile visual checks passed for the dashboard, knowledge-base, document, chat, and Analysis surfaces.
- Windows Sandbox validation on 2026-07-22 proved installation, packaged backend health, authentication, knowledge-base creation, document upload, CSV discovery, and CSV profile without a development toolchain. The UI could not render because the previous installer did not make WebView2 Runtime available; this candidate remains blocked until an offline-WebView2 rebuild passes the same clean-machine test.

## Blocking Gates

- Run the full checklist on a clean Windows machine or VM without Python, Node.js, Rust, Git, or project source code.
- Rebuild with the offline WebView2 Runtime and confirm the UI renders without a separate runtime installation.
- Obtain a valid code-signing certificate, or record explicit approval for an unsigned tester release and include the exact disclosure in the release notes.
- Replace the remaining `not tested` clean-machine results with attached validation evidence.

Do not create a public GitHub Release until every blocking gate is resolved and the release validation issue records a `Ready` decision.
