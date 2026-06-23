# Project Status

Last updated: 2026-06-22

This document tracks the practical delivery status of KnowBase.

## Current Progress

| Area | Progress | Notes |
| --- | ---: | --- |
| Resume and interview showcase | 96% | Strong project story, architecture, RAG workflow, packaging path, release process, CI history, customer-readiness narrative, and beta testing workflow are present. |
| GitHub portfolio completeness | 97% | README, architecture, roadmap, changelog, support, security, release docs, demo data, CI, release gates, issue templates, and desktop artifacts are in place. |
| Customer-installable software | 97% | Windows installer artifact is produced and locally verified; release preflight, validation, troubleshooting, beta, privacy, support workflows, Windows Credential Manager API key storage, encrypted fallback API key storage, per-install desktop secrets, a branded app icon, and installer metadata are ready, but real clean-machine validation is still required before customer release. |

## Verified

- Backend test suite passes locally: 49 tests.
- Frontend production build passes in GitHub Actions.
- Backend executable packaging foundation exists with PyInstaller.
- Tauri desktop shell exists and is configured for Windows bundle builds.
- Desktop package workflow runs automatically on relevant `main` pushes.
- Desktop package workflow succeeded on run `27772144566` for commit `41e6c84`.
- Uploaded CI artifacts:
  - `KnowBaseDesktop-Windows-3`
  - `KnowBaseBackend-3`
- Downloaded artifact `KnowBaseDesktop-Windows-3.zip` verified locally:
  - ZIP SHA256: `552E81842025B52D0B9C106257D2B2D08E69CA52BCD9169DF5F87A31F699FB26`
  - Installer inside ZIP: `KnowBase_0.1.0_x64-setup.exe`
- Release package preparation script generates:
  - installer copy for GitHub Release upload,
  - `SHA256SUMS.txt`,
  - `RELEASE_ARTIFACTS.md`,
  - `RELEASE_NOTES_DRAFT.md`,
  - `RELEASE_VALIDATION_ISSUE_DRAFT.md`.
- GitHub issue form exists for release validation tracking.
- GitHub issue form exists for structured beta feedback.
- Installed app check script exists for clean-machine evidence capture.
- Support info script exists for non-sensitive installation and startup triage reports.
- Local data removal script exists with dry-run by default and explicit `-ConfirmDelete` for uninstall, reinstall, or privacy cleanup workflows.
- Customer troubleshooting, customer beta test plan, and privacy notice draft are documented.
- Packaged Windows desktop runtime stores saved provider API keys through Windows Credential Manager; the database stores only a credential reference.
- Local Windows Credential Manager smoke passed with a fake `KnowBase:smoke:*` secret: write, read, and delete succeeded.
- Non-desktop fallback modes encrypt saved provider API keys before storage in the local application database, with legacy plaintext compatibility for existing local data.
- Packaged desktop runtime creates and reuses a per-install `app.secret` for local tokens and saved API key encryption.
- Tauri bundle includes a branded KnowBase app icon.
- Tauri bundle metadata includes publisher, homepage, copyright, category, and installer descriptions.
- Code signature check script exists and release package drafts record installer signature status.
- CI checks PowerShell script syntax to catch release-script parse errors.
- CI checks backend, desktop app, and release-draft version consistency.
- CI blocks tracked `.env`, local databases, uploads, artifacts, and desktop build outputs.
- CI checks required release documentation paths and references.
- CI runs the release preflight script that aggregates repository checks before packaging or publishing.
- Last confirmed full CI run before this update: run `27832480404` for commit `251b489`.
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
