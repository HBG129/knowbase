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
- `uploads\` - uploaded document files.
- conversation records, document metadata, knowledge base records, and user records inside the SQLite database.

If a user saves a personal LLM API key in the app, it is also stored in the local application database. Treat the data directory as sensitive.

## What Leaves The Machine

KnowBase sends content to the configured LLM provider when the user asks questions or processes documents for embeddings.

Depending on the provider key configured by the user, requests may go to:

- Zhipu GLM
- DeepSeek
- OpenAI

Do not upload private or regulated documents unless the selected provider and account terms are acceptable for that use case.

## What Is Not Ready For Enterprise Release

Before enterprise or public customer release, these items should be reviewed:

- Encrypt stored API keys or move them to an OS credential store.
- Define backup and restore behavior.
- Define uninstall behavior for local documents and database files.
- Add a clear privacy notice in the installed app.
- Review logs to ensure API keys and document contents are not written accidentally.

## Safe Support Instructions

When helping a customer debug issues:

- Do not ask the customer to send the full `%APPDATA%\KnowBase` directory.
- Do not ask for API keys in screenshots, logs, or chat.
- Ask for screenshots of error messages with sensitive values hidden.
- If a database sample is required, create a separate test account with non-sensitive files.
