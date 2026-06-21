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
- conversation records, document metadata, knowledge base records, and user records inside the SQLite database.

If a user saves a personal LLM API key in the packaged Windows desktop app, the secret is stored through Windows Credential Manager and the local database stores only a credential reference. Development or non-desktop fallback modes may store an encrypted API key record in the local database. Treat the data directory as sensitive.

## What Leaves The Machine

KnowBase sends content to the configured LLM provider when the user asks questions or processes documents for embeddings.

Depending on the provider key configured by the user, requests may go to:

- Zhipu GLM
- DeepSeek
- OpenAI

Do not upload private or regulated documents unless the selected provider and account terms are acceptable for that use case.

## What Is Not Ready For Enterprise Release

Before enterprise or public customer release, these items should be reviewed:

- Define backup and restore behavior.
- Define uninstall behavior for local documents and database files.
- Add a clear privacy notice in the installed app.
- Review logs to ensure API keys and document contents are not written accidentally.

## Backup And Restore

Before uninstalling, reinstalling, or moving to another machine, back up:

```text
%APPDATA%\KnowBase
```

This preserves:

- local accounts,
- the local app secret required to read encrypted fallback API key records,
- saved API key records,
- knowledge bases,
- uploaded documents,
- conversation history,
- document processing metadata.

To restore data, close KnowBase, replace the target `%APPDATA%\KnowBase` directory with the backed-up copy, then reopen the app.

Do not restore a production customer's data onto a shared or untrusted machine.

## Uninstall And Data Removal

The final Windows installer behavior is not locked yet.

Until the installer explicitly offers a data removal option, assume uninstalling the app may leave local data behind under:

```text
%APPDATA%\KnowBase
```

To remove local KnowBase data manually:

1. Close KnowBase.
2. Confirm no `KnowBaseBackend.exe` process is still running.
3. Back up `%APPDATA%\KnowBase` if the customer may need the data later.
4. Delete `%APPDATA%\KnowBase`.

Manual deletion removes uploaded documents, local accounts, conversation history, saved API key records, and the local SQLite database.

Do not delete this directory during support unless the customer understands the data loss.

## Safe Support Instructions

When helping a customer debug issues:

- Do not ask the customer to send the full `%APPDATA%\KnowBase` directory.
- Do not ask for API keys in screenshots, logs, or chat.
- Ask for screenshots of error messages with sensitive values hidden.
- If a database sample is required, create a separate test account with non-sensitive files.
