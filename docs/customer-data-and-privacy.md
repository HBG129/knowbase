# Customer Data And Privacy

This document explains where KnowBase stores customer data in the Windows desktop runtime.

## Data Location

In the packaged desktop runtime, KnowBase stores local data under:

```text
%APPDATA%\KnowBase
```

Usually this resolves to:

```text
C:\Users\<WindowsUser>\AppData\Roaming\KnowBase
```

For development and testing, the data directory can be overridden with:

```powershell
$env:KNOWBASE_DATA_DIR = "D:\path\to\test-data"
```

## What Is Stored

The desktop data directory contains:

- `knowbase.db` - local SQLite database.
- `app.secret` - per-install secret used for local tokens and encrypted fallback API key records.
- `uploads\` - uploaded document files.
- conversation records, document metadata, knowledge base records, user records, and saved CSV data analysis history inside the SQLite database.

If a user saves a personal LLM API key in the packaged Windows desktop app, the secret is stored through Windows Credential Manager and the local database stores only a credential reference. Development or non-desktop fallback modes may store an encrypted API key record in the local database. Treat the data directory as sensitive.

The desktop WebView profile is stored separately under:

```text
%LOCALAPPDATA%\com.hbg129.knowbase
```

It can contain session tokens, language and theme preferences, and an email address only when the user enables `Remember email`. KnowBase does not persist the login password in WebView storage. Upgrades from older builds remove the legacy remembered-login record when the login screen loads.

## What Leaves The Machine

KnowBase sends content to the configured LLM provider when the user asks questions or processes documents for embeddings.

CSV data analysis also uses the configured LLM provider. For analysis requests, KnowBase may send the user's analysis question, CSV column names, column profile information, generated SQL instructions, and a limited sample of query results so the provider can generate SQL and summarize the result. The full uploaded CSV file remains in the local uploads directory unless the user asks questions or analyses that require sending derived context to the selected provider.

Depending on the provider key configured by the user, requests may go to:

- Zhipu GLM
- DeepSeek
- OpenAI

Do not upload private or regulated documents unless the selected provider and account terms are acceptable for that use case.

## Backup And Restore

Before uninstalling, reinstalling, or moving to another machine, preview a local backup:

```powershell
.\scripts\backup-local-data.ps1
```

Create a local ZIP backup only after confirming the output path:

```powershell
.\scripts\backup-local-data.ps1 -ConfirmBackup
```

The backup ZIP preserves:

- local accounts,
- the local app secret required to read encrypted fallback API key records,
- knowledge bases,
- uploaded documents,
- conversation history,
- document processing metadata.

Credential Manager API keys are not exported by the backup script. After restoring on a different Windows profile or machine, add the provider API key again from the app if needed.

To preview a restore:

```powershell
.\scripts\restore-local-data.ps1 -ZipPath D:\path\to\knowbase-data-backup.zip
```

To restore data, close KnowBase, confirm no existing `%APPDATA%\KnowBase` directory is present, then run:

```powershell
.\scripts\restore-local-data.ps1 -ZipPath D:\path\to\knowbase-data-backup.zip -ConfirmRestore
```

The restore script refuses to overwrite an existing `KnowBase` data directory. Back up and remove the current data directory before restoring over it.

Do not restore a production customer's data onto a shared or untrusted machine.

## Uninstall And Data Removal

Uninstalling KnowBase removes the application but intentionally preserves customer data under:

```text
%APPDATA%\KnowBase
```

The WebView profile under `%LOCALAPPDATA%\com.hbg129.knowbase` may also remain so reinstalling does not silently destroy the customer's session and preferences.

To remove local KnowBase data manually:

1. Close KnowBase.
2. Confirm no `KnowBaseBackend.exe` process is still running.
3. Back up `%APPDATA%\KnowBase` if the customer may need the data later.
4. Preview the removal plan:

```powershell
.\scripts\remove-local-data.ps1
```

5. Remove the local data directory and KnowBase Windows Credential Manager targets:

```powershell
.\scripts\remove-local-data.ps1 -ConfirmDelete
```

Confirmed removal deletes uploaded documents, local accounts, conversation history, saved API key records, the local SQLite database, the WebView profile and session tokens, and KnowBase Credential Manager targets.

Do not run confirmed removal during support unless the customer understands the data loss.

## Safe Support Instructions

When helping a customer debug issues:

- Do not ask the customer to send the full `%APPDATA%\KnowBase` directory.
- Do not ask for API keys in screenshots, logs, or chat.
- Ask for screenshots of error messages with sensitive values hidden.
- If a database sample is required, create a separate test account with non-sensitive files.
