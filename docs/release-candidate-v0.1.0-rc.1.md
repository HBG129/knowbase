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

- Latest pushed source commit: `eaf71d9789db51327ad177ea8a659d5caca3e697`
- PR CI run `29911275920`: repository checks, backend tests, and frontend build passed.
- Desktop package run `29911326668`: backend tests, frontend build, PyInstaller, Tauri/NSIS packaging, packaged-backend health, artifact verification, signature status check, and both artifact uploads passed.
- GitHub artifact: `KnowBaseDesktop-Windows-27`
- Artifact ZIP SHA256: `73F0A86CA3FB7EFE8CF5443AA7586C2B2C4210136470F240ADD8DB82A2E99268`
- The current working revision pins Next.js `15.5.21`, Next's bundled PostCSS `8.5.18`, and WebView2 Fixed Version Runtime `150.0.4078.99`; local backend tests, frontend production build, production dependency audit, and runtime preparation pass.
- The current local fixed-runtime NSIS build completed successfully. `KnowBase_0.1.0_x64-setup.exe` is `308045565` bytes with SHA256 `9991CD2E4B29A1CFAD790AF63D1E93DF8B49626CDC4F090B02E113C54B7408EF`; Authenticode status is `NotSigned`.
- Local upgrade/install verification passed for shortcuts, bundled backend startup, listener ownership, health response, and process cleanup after closing the desktop window.
- Complete Chinese/English desktop and mobile visual checks passed for the dashboard, knowledge-base, document, chat, and Analysis surfaces.
- Windows Sandbox validation on 2026-07-22 proved that a local fixed-runtime installer rendered the UI and passed packaged backend health, authentication, knowledge-base creation, Markdown/CSV upload, dataset discovery, and CSV profile without a development toolchain or separate WebView2 installation.
- The Sandbox report did not prove app close and orphan-process cleanup because no manual close action occurred before the timeout. The current source revision and its exact CI artifact still require that check plus uninstall validation.

## Blocking Gates

- Build the current fixed-runtime source revision in GitHub Actions and validate that exact artifact on a clean Windows machine or VM.
- Confirm app close, orphan-process cleanup, uninstall, and real-provider cited chat and CSV Analysis with the exact candidate artifact.
- Obtain a valid code-signing certificate, or record explicit approval for an unsigned tester release and include the exact disclosure in the release notes.
- Replace the remaining `not tested` clean-machine results with attached validation evidence.

Do not create a public GitHub Release until every blocking gate is resolved and the release validation issue records a `Ready` decision.
