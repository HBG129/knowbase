# Clean Machine Validation

Use this checklist before publishing a KnowBase Windows installer to customers.

## Goal

A customer should be able to install and use KnowBase without installing Python, Node.js, Rust, Git, or the project source code.

## Test Machine

Use a Windows machine or VM that does not have the development stack installed.

Allowed:

- Internet access
- A valid LLM provider API key
- Standard Windows user permissions

Not allowed:

- Python
- Node.js
- Rust
- Git
- Local project checkout

## Artifact Check

Download the latest `KnowBaseDesktop-Windows-<run number>` artifact from GitHub Actions.

For the latest prepared release package on the development machine, read:

```text
D:\Codex_AI_Workspace\artifacts\knowbase-release\SHA256SUMS.txt
```

Before installing, verify the ZIP from the development machine:

```powershell
.\scripts\check-release-artifact.ps1 `
  -ZipPath D:\Codex_AI_Workspace\knowbase\data\downloaded-artifacts\KnowBaseDesktop-Windows-<run number>.zip `
  -ExpectedSha256 <zip sha256 from SHA256SUMS.txt>
```

Expected result:

```text
Release artifact verified.
```

## Install And Launch

1. Extract the artifact ZIP.
2. Run the `KnowBase_0.1.0_x64-setup.exe` installer.
3. Extract `KnowBaseSupportTools.zip` from the prepared release package.
4. Launch KnowBase from the Start Menu or desktop shortcut.
5. Confirm the app opens without a developer terminal.
6. Confirm no Python, Node.js, Rust, Git, or source-code path is required.

## First-Run Flow

Validate:

- User registration succeeds.
- Login succeeds.
- A knowledge base can be created.
- The API key settings flow accepts a valid provider key.
- PDF, Word, Markdown, TXT, and CSV uploads are accepted.
- CSV Analysis tab can preview data, answer a question, render a chart, show a summary, and restore the run from history.
- Uploaded files appear in the document list.
- Chat is disabled until the knowledge base has usable documents.
- Chat returns an answer with citations after ingestion completes.
- Recent conversations reopen correctly.
- Conversation deletion uses the in-app confirmation flow.

## Runtime Checks

Validate:

- Backend starts automatically when the desktop app opens.
- App data is stored under `%APPDATA%\KnowBase`.
- Closing the app stops the backend process.
- Installing or uninstalling while KnowBase is still running stops `KnowBase.exe` and `KnowBaseBackend.exe` before overwriting files.
- Relaunching the app keeps existing account, knowledge base, documents, and conversations.
- No API key or document content appears in visible logs.

After installing and launching KnowBase, run the installed app check script:

```powershell
cd .\support-tools
powershell -ExecutionPolicy Bypass -File .\check-installed-app.ps1
```

The script writes a local Markdown report to the current user's Desktop under:

```text
KnowBaseValidation
```

The report includes installed executable version, signature status, and backend process path when available. Review those fields before attaching the report to a release validation issue.

If any check fails, the script exits with a non-zero status. Use `-AllowFailures` only when you need a report for investigation without blocking the current shell session.

Use the report as supporting evidence for the GitHub `Release validation` issue. Do not attach local databases, uploaded documents, API keys, or `%APPDATA%\KnowBase` contents.

If any install, launch, backend, or health check fails, also generate a non-sensitive support report:

```powershell
powershell -ExecutionPolicy Bypass -File .\collect-support-info.ps1
```

Use `docs\customer-troubleshooting.md` to classify the failure before deciding whether to block the release.

## Release Decision

Do not publish the installer if any of these fail:

- Installer does not run on the clean machine.
- App requires developer tools.
- Backend does not start automatically.
- Registration or login fails.
- Document upload or chat fails with valid provider credentials.
- CSV Analysis tab preview, query, chart, summary, or history fails for a completed CSV.
- App leaves orphan backend processes after exit.
- Sensitive data is exposed in logs or release artifacts.
