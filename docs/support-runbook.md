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

## Escalation Notes

Escalate internally when:

- a reproducible crash affects packaged desktop startup,
- a security or privacy issue may expose local data or API keys,
- a release artifact fails clean-machine installation,
- a model/provider failure is reproducible with a valid key and non-sensitive test file.

Use GitHub issues with the provided templates for non-sensitive tracking.
