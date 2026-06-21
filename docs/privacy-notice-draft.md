# Privacy Notice Draft

This draft explains the current KnowBase desktop privacy model for testers and early users.

This is not a final legal privacy policy. Review it before any public or enterprise release.

## What KnowBase Stores Locally

In the packaged Windows desktop runtime, KnowBase stores app data under:

```text
%APPDATA%\KnowBase
```

This may include:

- local account records,
- knowledge base metadata,
- uploaded document files,
- document processing metadata,
- conversation history,
- encrypted provider API key records,
- a per-install app secret used for local tokens and saved API key encryption,
- the local SQLite database.

Treat the full `%APPDATA%\KnowBase` folder as sensitive.

## What May Leave The Machine

KnowBase sends content to the configured LLM provider when the user asks questions or when document content is processed for embeddings.

Supported provider choices may include:

- Zhipu GLM
- DeepSeek
- OpenAI

Provider behavior, retention, pricing, regional availability, and terms are controlled by the selected provider.

Do not upload private, regulated, confidential, or production business documents unless the selected provider and account terms are acceptable for that use case.

## What KnowBase Does Not Collect For Support

Support should not request:

- API keys,
- `.env` files,
- `knowbase.db`,
- uploaded documents,
- the full `%APPDATA%\KnowBase` folder,
- screenshots that reveal secrets or private document contents.

For installation or startup triage, use the non-sensitive support report:

```powershell
.\scripts\collect-support-info.ps1
```

Review the generated Markdown report before sharing it.

## Current Security Limitations

Before public or enterprise release, these areas still need review:

- saved API keys should move to an OS credential store or equivalent secure storage,
- local database encryption is not implemented,
- code signing is not configured,
- enterprise privacy notice and in-app legal copy are not final,
- logs should continue to be reviewed for accidental API key or document content exposure.

## Data Removal

Uninstall behavior is not finalized. Until the installer explicitly offers a data removal option, assume uninstalling the app may leave local data behind under:

```text
%APPDATA%\KnowBase
```

Manual deletion of this folder removes local accounts, uploaded documents, knowledge bases, conversations, saved API key records, and the local SQLite database.

Do not delete this folder unless the user understands the data loss.
