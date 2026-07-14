# Project Status

Last updated: 2026-07-13

This document tracks the practical delivery status of KnowBase.

## Current Progress

| Area | Progress | Notes |
| --- | ---: | --- |
| Resume and interview showcase | 98% | Strong project story, architecture, RAG workflow, CSV Analysis Agent, packaging path, release process, CI history, customer-readiness narrative, beta testing workflow, and installed-app evidence are present. |
| GitHub portfolio completeness | 98% | README, architecture, roadmap, project plan, changelog, support, security, release docs, demo data, CI, release gates, issue templates, branded desktop icon, and desktop artifacts are in place. |
| Limited tester readiness | 95% | Windows installer artifact is produced by GitHub Actions and locally install-verified; release preflight, validation, troubleshooting, beta, privacy, support workflows, Windows Credential Manager API key storage, encrypted fallback API key storage, per-install desktop secrets, branded app icon, installer metadata, installer process cleanup, and CSV analysis validation are ready for controlled testing. |
| Public customer release readiness | 85% | Core workflows and release automation are strong, but clean-machine validation, final release notes, final version decision, and code signing or explicit unsigned-release disclosure are still required before public customer release. |

## Verified

- Backend test suite passes locally.
- Frontend production build passes in GitHub Actions.
- Backend executable packaging foundation exists with PyInstaller.
- Tauri desktop shell exists and is configured for Windows bundle builds.
- Desktop package workflow runs automatically on relevant `main` pushes.
- Desktop package workflow succeeded on run `28660401375` for commit `27450da`.
- Uploaded CI artifacts:
  - `KnowBaseDesktop-Windows-20`
  - `KnowBaseBackend-20`
- Downloaded artifact `KnowBaseDesktop-Windows-20.zip` verified locally:
  - ZIP SHA256: `01EA38B6DB0773B106E1555EF304FAB17D3BBEDCE519A12DDA3D3F23B9CBC4BF`
  - Installer inside ZIP: `KnowBase_0.1.0_x64-setup.exe`
  - Installer size: `72109572` bytes
- Local install verification for `KnowBaseDesktop-Windows-20` passed:
  - installer runs silently with exit code `0`,
  - desktop shortcut and Start Menu shortcut are present,
  - `KnowBase.exe` starts,
  - `KnowBaseBackend.exe` starts automatically,
  - exactly one backend process listens on `127.0.0.1:8000`,
  - health endpoint returns `{"status":"ok"}`.
- Existing `KnowBaseDesktop-Windows-21` installation was validated locally:
  - installer SHA256 matches `23F82866D3A0F4AEFF6020A71B24C2B25B2ADBE748988B44D969602070531BEC`,
  - desktop and Start Menu shortcuts resolve to the custom installation directory,
  - the desktop app starts its packaged backend automatically,
  - the `127.0.0.1:8000` listener belongs to a detected `KnowBaseBackend.exe` under the installation directory,
  - the health endpoint returns `{"status":"ok"}`,
  - closing the desktop window stops both the app and backend processes.
- Packaged backend core API smoke passed with isolated data on `127.0.0.1:8765`:
  - health endpoint returned `{"status":"ok"}`,
  - user registration and login succeeded,
  - authenticated `/api/auth/me` succeeded,
  - knowledge base creation and listing succeeded,
  - demo Markdown upload completed with `2` chunks,
  - document listing returned the uploaded document,
  - temporary backend process tree was stopped after validation.
- Release package preparation script generates:
  - installer copy for GitHub Release upload,
  - `KnowBaseSupportTools.zip` for customer/tester validation reports,
  - `SHA256SUMS.txt`,
  - `RELEASE_ARTIFACTS.md`,
  - `RELEASE_NOTES_DRAFT.md`,
  - `RELEASE_VALIDATION_ISSUE_DRAFT.md`.
- Prepared B20 release package includes support tools:
  - `support-tools\check-installed-app.ps1`,
  - `support-tools\collect-support-info.ps1`,
  - `support-tools\README.txt`,
  - `KnowBaseSupportTools.zip`.
- Extracted `KnowBaseSupportTools.zip` was smoke-tested locally:
  - `collect-support-info.ps1` generated a non-sensitive support report,
  - `check-installed-app.ps1 -AllowFailures` generated an installed-app report.
- Frontend API client handles successful empty responses such as `204 No Content`, preventing successful conversation delete or clear-message actions from being reported as failed JSON parsing.
- CSV Analysis Agent is implemented for completed CSV documents:
  - dataset listing, preview, profile, and recommended questions,
  - LLM-generated read-only DuckDB SQL,
  - SQL guard for writes, DDL, local file access, extension loading, generated table functions, and dataset relation shadowing,
  - DuckDB execution with result limiting,
  - lightweight chart spec, summary, insights, failed-run recording, and independent analysis history.
- CSV Analysis Agent handles summary-generation failure after successful SQL execution by returning the computed rows, chart, SQL, and a fallback summary.
- API key saving falls back to encrypted local database storage if Windows Credential Manager is unavailable or rejects a credential write, preventing the API key settings flow from failing solely because the OS credential store is unavailable.
- Release preflight now includes a frontend empty-response API check.
- Release preflight now keeps generated smoke artifacts outside the git working tree.
- Release preflight now generates the release package and verifies the actual support tools ZIP entries, README contents, and checksum.
- Packaged backend health check starts `KnowBaseBackend.exe` on an isolated port, verifies `/api/health`, cleans up its default temporary data directory, and stops the temporary backend process.
- GitHub issue form exists for release validation tracking.
- GitHub issue form exists for structured beta feedback.
- Installed app check script exists for clean-machine evidence capture and reports installed executable version, signature status, and backend process path when available.
- Support info script exists for non-sensitive installation and startup triage reports.
- Local data backup script exists with dry-run by default and explicit `-ConfirmBackup` for customer-owned backup workflows.
- Local data removal script exists with dry-run by default and explicit `-ConfirmDelete` for uninstall, reinstall, or privacy cleanup workflows.
- Local data restore script exists with dry-run by default and refuses to overwrite an existing `KnowBase` data directory.
- Customer troubleshooting, customer beta test plan, and privacy notice draft are documented.
- Packaged Windows desktop runtime stores saved provider API keys through Windows Credential Manager; the database stores only a credential reference.
- Local Windows Credential Manager smoke passed with a fake `KnowBase:smoke:*` secret: write, read, and delete succeeded.
- Non-desktop fallback modes encrypt saved provider API keys before storage in the local application database, with legacy plaintext compatibility for existing local data.
- Packaged desktop runtime creates and reuses a per-install `app.secret` for local tokens and saved API key encryption.
- Tauri bundle includes a simplified branded knowledge-cube KnowBase app icon.
- Tauri bundle metadata includes publisher, homepage, copyright, category, and installer descriptions.
- NSIS installer hooks stop `KnowBase.exe` and `KnowBaseBackend.exe` before install or uninstall file operations.
- Code signature check script exists and release package drafts record installer signature status.
- Release package preparation blocks a non-`Valid` installer signature unless `-AllowUnsigned` is explicitly supplied for an approved build with release-note disclosure.
- Release validation records the signature policy decision and requires valid signer evidence or the unsigned approver, approval date, and exact release-notes disclosure.
- Desktop packaging workflow records installer code signature status after NSIS bundle generation.
- CI checks PowerShell script syntax to catch release-script parse errors.
- CI checks backend, desktop app, and release-draft version consistency.
- CI blocks tracked `.env`, local databases, uploads, artifacts, and desktop build outputs.
- CI checks required release documentation paths and references.
- CI runs the release preflight script that aggregates repository checks before packaging or publishing.
- Frontend production dependency audit is release-clean on Next.js 15.5.20 with Next's bundled PostCSS overridden to 8.5.10; `npm audit --omit=dev --audit-level=high` reports zero vulnerabilities.
- Last confirmed CI run: run `28661323870` for commit `33de9e7`.
- Desktop artifact verification script checks for:
  - `backend\dist\KnowBaseBackend.exe`
  - NSIS installer under `frontend\src-tauri\target\release\bundle\nsis`
- Synthetic demo files exist for safe screenshots, GIFs, and release validation.

## Current Blockers

### Local machine

The local machine still lacks Microsoft C++ Build Tools:

```text
cl.exe missing
link.exe missing
```

This blocks local Tauri installer builds.

### GitHub Actions

The desktop package workflow is currently passing:

- backend tests pass,
- frontend build passes,
- backend executable packaging completes,
- Tauri Windows packaging completes,
- installer artifact verification passes,
- backend executable and desktop installer bundle artifacts upload successfully.

## Next Required Checks

1. Install `KnowBase_0.1.0_x64-setup.exe` on a clean Windows machine or VM.
2. Validate:
   - app launches,
   - backend starts automatically,
   - user can register,
   - knowledge base can be created,
   - demo documents upload,
   - chat returns cited answers,
   - app exits without orphan backend process.

## Not Release Ready Until

- The installer is tested on a clean Windows machine.
- The installer has a valid code signature, or release notes explicitly state that the build is unsigned.
- The final public release version is selected.
- Release notes include exact verification results.
