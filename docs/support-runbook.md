# Support Runbook

Use this runbook when triaging KnowBase customer or tester issues.

## First Rule

Do not ask customers to send:

- API keys,
- `.env` files,
- `knowbase.db`,
- uploaded documents,
- full `%APPDATA%\KnowBase` folders,
- screenshots that show secrets or private document contents.

Ask for redacted screenshots and non-sensitive error text first.

If the issue involves installation or desktop startup, ask the customer to run:

```powershell
.\scripts\collect-support-info.ps1
```

They may attach the generated Markdown report after checking it for private details. The script does not collect API keys, database contents, uploaded document contents, or uploaded file names.

## Basic Triage

Collect:

- KnowBase version or commit.
- Windows version.
- How KnowBase is running: local development, backend executable, Tauri app, or GitHub Actions artifact.
- Whether the issue happens every time.
- Exact reproduction steps.
- Expected behavior.
- Actual behavior.

## Common Issue Paths

### App Does Not Launch

Check:

- Was it installed from a packaged build or run from source?
- Is `KnowBaseBackend.exe` present in the packaged resources?
- Does the backend health endpoint respond?
- Does closing and reopening leave orphan backend processes?

Relevant docs:

```text
docs\desktop-build-troubleshooting.md
docs\release-process.md
```

Relevant script:

```text
scripts\collect-support-info.ps1
```

### API Key Or Model Error

Check:

- Is a personal provider key configured from `Set API Key`?
- Is the selected provider Zhipu GLM, DeepSeek, or OpenAI?
- Is the provider account active and in quota?
- Does the machine have internet access?

Do not ask the customer to paste the key.

### Upload Or Document Processing Fails

Check:

- File type: PDF, Word, Markdown, TXT, or CSV.
- File size.
- Whether processing completed.
- Whether the customer is trying to upload private or regulated data to a provider they have approved.

### Chat Has No Useful Answer

Check:

- At least one document is processed.
- The question is related to uploaded content.
- Citations appear.
- The provider key is valid and not rate-limited.

## Local Data

Desktop runtime data is stored under:

```text
%APPDATA%\KnowBase
```

Do not request the full directory. If data inspection is unavoidable, ask the customer to reproduce with a test account and non-sensitive files.

For uninstall, reinstall, or privacy cleanup cases, ask the customer to preview the local data removal plan first:

```powershell
.\scripts\remove-local-data.ps1
```

If the customer may need their data later, ask them to create a local backup before confirmed removal:

```powershell
.\scripts\backup-local-data.ps1
.\scripts\backup-local-data.ps1 -ConfirmBackup
```

Remind the customer not to share the backup ZIP with support.

Only ask them to run confirmed removal after they understand that local accounts, uploaded documents, conversations, the local database, and KnowBase credential targets will be deleted:

```powershell
.\scripts\remove-local-data.ps1 -ConfirmDelete
```

## Escalation Notes

Escalate internally when:

- a reproducible crash affects packaged desktop startup,
- a security or privacy issue may expose local data or API keys,
- a release artifact fails clean-machine installation,
- a model/provider failure is reproducible with a valid key and non-sensitive test file.

Use GitHub issues with the provided templates for non-sensitive tracking.
