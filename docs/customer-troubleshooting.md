# Customer Troubleshooting

Use this guide when the packaged Windows desktop app does not behave as expected.

Do not share API keys, `.env` files, local databases, uploaded documents, or the full `%APPDATA%\KnowBase` folder when asking for help.

## App Does Not Open

Check:

1. Start KnowBase from the Windows Start Menu or desktop shortcut.
2. Wait at least 10 seconds after launch.
3. Open Task Manager and check whether `KnowBase.exe` is running.
4. If the app still does not open, restart Windows and try again.

For support, generate a non-sensitive report:

```powershell
.\scripts\collect-support-info.ps1
```

Attach only the generated Markdown report after checking it for private details.

## Backend Does Not Start

Symptoms:

- the app opens but pages keep loading,
- chat cannot connect,
- health checks fail,
- `KnowBaseBackend.exe` is not running.

Check:

1. Close KnowBase.
2. Confirm no old `KnowBaseBackend.exe` process is still running.
3. Reopen KnowBase.
4. Run the support report script and check the backend process count.

```powershell
.\scripts\collect-support-info.ps1
```

## Login Or Registration Fails

Check:

1. Confirm the app data directory exists:

```text
%APPDATA%\KnowBase
```

2. Confirm the app has permission to write under the Windows user profile.
3. Try registering a new local account.

Do not delete `%APPDATA%\KnowBase` unless you understand that this removes local accounts, uploaded documents, knowledge bases, conversations, and saved API key records.

## API Key Or Model Error

Check:

1. Confirm a provider key is configured from:

```text
Sidebar -> Set API Key
```

2. Confirm the selected provider matches the key:

- Zhipu GLM
- DeepSeek
- OpenAI

3. Confirm the provider account is active, in quota, and available from the current network.
4. Do not paste API keys into GitHub issues, screenshots, or support messages.

## Upload Or Processing Fails

Supported files:

- PDF
- Word
- Markdown
- TXT
- CSV

Check:

1. Confirm the file type is supported.
2. Try a small non-sensitive test file.
3. Wait for processing to finish before opening chat.
4. If one specific file fails, retry with a sanitized sample that contains no private data.

## Chat Has No Useful Answer

Check:

1. At least one document has finished processing.
2. The question is related to uploaded document content.
3. The provider key is valid and not rate-limited.
4. Citations appear with the answer.

If citations are missing or irrelevant, the document may not have been processed correctly, or the question may be outside the uploaded content.

## Safe Support Checklist

Before opening an issue:

1. Remove secrets from screenshots.
2. Do not attach uploaded documents.
3. Do not attach `knowbase.db`.
4. Do not attach `%APPDATA%\KnowBase`.
5. Include KnowBase version or commit, Windows version, reproduction steps, expected behavior, and actual behavior.

For support triage, see:

```text
docs\support-runbook.md
```
