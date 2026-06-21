# Security Policy

KnowBase is a desktop-first AI knowledge base application that handles local documents, local account data, and LLM provider API keys.

## Supported Versions

KnowBase has not published a customer installer yet.

Until the first customer release, security fixes are handled on the `main` branch.

## Reporting A Security Issue

Do not report security issues by posting private documents, API keys, local databases, or full `%APPDATA%\KnowBase` folders in a public GitHub issue.

For now, report security concerns by opening a GitHub issue with only non-sensitive reproduction details. If private details are required, first open a minimal issue asking for a private coordination path.

Include:

- affected commit, branch, or release,
- operating system,
- whether the issue affects local development, backend executable, or desktop app,
- minimal reproduction steps,
- expected behavior,
- actual behavior,
- any non-sensitive logs.

Do not include:

- LLM API keys,
- `.env` files,
- `knowbase.db`,
- uploaded documents,
- `%APPDATA%\KnowBase` archives,
- screenshots that show secrets or private document contents.

## Sensitive Data

Treat these as sensitive:

- `.env`
- `JWT_SECRET_KEY`
- `OPENAI_API_KEY`
- `ZHIPU_API_KEY`
- customer-provided provider keys
- `%APPDATA%\KnowBase`
- `knowbase.db`
- `uploads\`
- screenshots of private documents or answers
- Windows Credential Manager entries created by KnowBase

## Current Security Limitations

These are known limitations before a public customer release:

- Packaged Windows desktop builds store saved API keys through Windows Credential Manager; development and fallback modes use encrypted local database storage.
- Local database encryption is not implemented yet.
- App signing is not configured yet.
- Auto-update is not configured yet.
- Enterprise privacy copy is not finalized.

See:

```text
docs\known-limitations.md
docs\customer-data-and-privacy.md
```

## Security Checklist For Contributors

Before submitting changes:

- Do not commit `.env`, databases, uploaded documents, or generated runtime data.
- Do not log API keys, authorization headers, refresh tokens, or document contents.
- Keep authentication and authorization checks on protected routes.
- Prefer customer-controlled provider keys unless a system fallback key is explicitly intended.
- Avoid adding public network exposure without reviewing CORS, auth, and storage behavior.
- Update documentation if a change affects data storage, API key handling, or release security.
