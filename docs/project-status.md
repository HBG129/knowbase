# Project Status

Last updated: 2026-07-22

This document tracks the practical delivery status of KnowBase.

## Current Progress

| Area | Progress | Notes |
| --- | ---: | --- |
| Resume and interview showcase | 98% | Strong project story, architecture, RAG workflow, CSV Analysis Agent, packaging path, release process, CI history, customer-readiness narrative, beta testing workflow, and installed-app evidence are present. |
| GitHub portfolio completeness | 98% | README, architecture, roadmap, project plan, changelog, support, security, release docs, demo data, CI, release gates, issue templates, branded desktop icon, and desktop artifacts are in place. |
| Limited tester readiness | 92% | The desktop build and backend workflows are strong, but the replacement installer with offline WebView2 must pass clean-machine UI validation before controlled distribution; signature policy and tester approval also remain open. |
| Public customer release readiness | 86% | Core workflows, complete bilingual UX, version selection, release automation, and clean-machine backend evidence are strong, but the offline-WebView2 rebuild, full UI/LLM clean-machine validation, final release notes, and code signing remain required. |

## Verified

- Backend test suite passes locally.
- Frontend production build passes in GitHub Actions.
- Backend executable packaging foundation exists with PyInstaller.
- Tauri desktop shell exists and is configured for Windows bundle builds.
- Desktop package workflow runs automatically on relevant `main` pushes.
- Desktop package workflow succeeded on run `28660401375` for commit `27450da`.
- Desktop package workflow succeeded on run `29498356330` for commit `b21b906` after verifying the packaged backend health and Analysis API contract on the GitHub-hosted Windows runner.
- Desktop package workflow succeeded on run `29639608446` for commit `6b3606b` after complete bilingual localization; backend tests, frontend build, PyInstaller, Tauri/NSIS, packaged-backend health, artifact checks, signature status, and both uploads passed.
- Uploaded CI artifacts:
  - `KnowBaseDesktop-Windows-24` (artifact SHA256 digest: `88eae540b31694bc954fe1e650d6d341fccfeccba8eb025944912a7a6c2206b5`)
  - `KnowBaseBackend-24` (artifact SHA256 digest: `94a29469da9264aafc0d234467e6a969731ba51d8172315a5e1cd682a873a84f`)
- Downloaded artifact `KnowBaseDesktop-Windows-20.zip` verified locally:
  - ZIP SHA256: `01EA38B6DB0773B106E1555EF304FAB17D3BBEDCE519A12DDA3D3F23B9CBC4BF`
  - Installer inside ZIP: `KnowBase_0.1.0_x64-setup.exe`
  - Installer size: `72109572` bytes
- Downloaded artifact `KnowBaseDesktop-Windows-24.zip` from run `29498356330` verified locally:
  - ZIP SHA256: `88EAE540B31694BC954FE1E650D6D341FCCFECCBA8EB025944912A7A6C2206B5`, matching the GitHub artifact digest,
  - installer inside ZIP: `KnowBase_0.1.0_x64-setup.exe`,
  - installer size: `85356036` bytes,
  - installer SHA256: `5D7BF11DC28213A9AF9BBB7F82F641AF527A7226C28BAF8B7D2EA659B8102E32`,
  - Authenticode status: `NotSigned`.
- Downloaded artifact `KnowBaseDesktop-Windows-25.zip` from run `29639608446` verified locally:
  - ZIP SHA256: `CB59221D736321049AC718F28E6FAC473E5695D00B441AF2A4A8FF0689579015`, matching the GitHub artifact digest,
  - installer inside ZIP: `KnowBase_0.1.0_x64-setup.exe`,
  - installer size: `85356855` bytes,
  - installer SHA256: `2B5148882FB19D8139ED0EA239CEF525F24CF7797178748AF702BBA988C610BD`,
  - Authenticode status: `NotSigned`.
- Release package prepared from `KnowBaseDesktop-Windows-24.zip`:
  - output: `D:\Codex_AI_Workspace\artifacts\knowbase-release-pr16-run-29498356330`,
  - support tools ZIP SHA256: `2A2260AE73214B88E83FBA8F66D5ADE68F6F88F7F993A9A8CCBBEAE924B02B63`,
  - generated checksums match the installer, source ZIP, and support tools ZIP,
  - support tools ZIP contains only `check-installed-app.ps1`, `collect-support-info.ps1`, and `README.txt`.
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
- Latest `KnowBaseDesktop-Windows-25` was upgrade-installed and validated locally:
  - existing custom installation directory and Start Menu/Desktop shortcuts were preserved,
  - installed file timestamps match desktop package run `29639608446`,
  - the desktop app started the packaged PyInstaller backend process tree,
  - exactly one `127.0.0.1:8000` listener belonged to the packaged backend child process,
  - the health endpoint returned `{"status":"ok"}`,
  - closing the desktop window removed the app process, both PyInstaller backend processes, and the listener within two seconds.
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
- Complete Chinese and English product localization now covers authentication, navigation, the knowledge-base dashboard, document workflows, cited chat, API key settings, CSV Analysis, errors, empty states, relative dates, and accessibility labels.
- Language preference hydrates after client mount, avoiding server/client language mismatches, and authentication routes remain correctly recognized with or without a trailing slash.
- CI and release preflight enforce Chinese/English key parity, reject unknown translation keys and duplicate entries, scan product surfaces for hardcoded interface copy and mojibake, and verify localized API and authentication behavior.
- Chinese and English localization was visually verified on desktop and mobile viewports, including the dashboard, knowledge-base details, document list, and CSV Analysis workspace.
- Last confirmed CI run: run `29639530539` for commit `6b3606b`; repository checks, backend tests, and frontend build passed.
- Desktop artifact verification script checks for:
  - `backend\dist\KnowBaseBackend.exe`
  - NSIS installer under `frontend\src-tauri\target\release\bundle\nsis`
- Synthetic demo files exist for safe screenshots, GIFs, and release validation.
- Windows Sandbox validation proved the unsigned installer can install on a machine without Python, Node.js, npm, Rust, Cargo, or Git; packaged backend health, authentication, knowledge-base creation, Markdown/CSV upload, dataset discovery, and CSV profile all passed.
- That clean-machine run also found a release-blocking UI failure: WebView2 Runtime was unavailable after installation. The Tauri bundle now explicitly selects the offline WebView2 installer, and a new desktop artifact must pass the same Sandbox validation before release.

## Current Blockers

### Release policy and clean-machine evidence

- The selected controlled tester candidate is `v0.1.0-rc.1`; the GA target is `v0.1.0` after all release gates pass.
- The current installer is `NotSigned`. Publishing requires a valid signature or explicit unsigned-release approval with exact release-note disclosure.
- The latest installer completed backend and core API checks in Windows Sandbox but failed UI launch because WebView2 Runtime was missing; the offline-WebView2 replacement has not yet completed the full clean-machine checklist.

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

1. Build and download a new `KnowBase_0.1.0_x64-setup.exe` with the offline WebView2 Runtime embedded.
2. Validate:
   - app renders without a separate WebView2 installation,
   - backend starts automatically,
   - user can register,
   - knowledge base can be created,
   - demo documents upload,
   - chat returns cited answers,
   - app exits without orphan backend process.

## Not Release Ready Until

- The installer is tested on a clean Windows machine.
- The installer has a valid code signature, or release notes explicitly state that the build is unsigned.
- Release notes include exact verification results.
