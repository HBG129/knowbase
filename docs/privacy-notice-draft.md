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
- provider API key references for Windows Credential Manager,
- encrypted provider API key records in fallback modes,
- a per-install app secret used for local tokens and fallback API key encryption,
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

- local database encryption is not implemented,
- the current validation candidate is unsigned; the protected production signing path is implemented but awaits production credentials,
- enterprise privacy notice and in-app legal copy are not final,
- logs should continue to be reviewed for accidental API key or document content exposure.

## Data Removal

Uninstalling KnowBase removes application binaries but intentionally preserves customer data under:

```text
%APPDATA%\KnowBase
```

This preservation behavior passed clean-machine validation. To remove all local app data, WebView session data, and KnowBase Credential Manager entries, use the dry-run-first `remove-local-data.ps1` support tool and explicitly confirm deletion only after reviewing its plan.

Do not delete this folder unless the user understands the data loss.
