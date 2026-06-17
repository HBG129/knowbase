# Contributing

Thanks for helping improve KnowBase.

KnowBase is still pre-release. Keep changes focused, easy to review, and aligned with the desktop-first product direction.

## Before You Start

Read:

```text
README.md
docs\README.md
docs\architecture.md
SECURITY.md
docs\known-limitations.md
docs\release-readiness-checklist.md
```

For customer-facing behavior, also read:

```text
docs\customer-quick-start.md
docs\customer-data-and-privacy.md
```

## Development Setup

Use the standard dev launcher from the repository root:

```powershell
.\start-dev.bat
```

Frontend:

```text
http://localhost:3000
```

Backend:

```text
http://127.0.0.1:8000
```

## Change Scope

Prefer small, surgical changes:

- Fix one problem at a time.
- Match existing code style.
- Avoid unrelated refactors.
- Do not add speculative abstractions.
- Update docs when behavior, packaging, security, or customer setup changes.

## Verification

Run the checks that match your change.

Frontend:

```powershell
cd frontend
npm run build
```

Backend:

```powershell
cd backend
.\.venv\Scripts\python.exe -m pytest tests -q
```

Desktop packaging prerequisites:

```powershell
.\check-desktop-prereqs.bat
```

Full desktop packaging:

```powershell
.\package-desktop.bat
```

If desktop packaging is blocked locally by missing Microsoft C++ Build Tools, use the manual GitHub Actions workflow:

```text
Desktop Package
```

## Security Rules

Do not commit:

- `.env`
- API keys
- uploaded documents
- local SQLite databases
- `%APPDATA%\KnowBase`
- generated build outputs
- `node_modules`
- virtual environments

Do not log:

- API keys
- authorization headers
- refresh tokens
- private document contents

See `SECURITY.md` for the full security policy.

## Pull Request Checklist

Before opening or merging a pull request:

- Use `.github\PULL_REQUEST_TEMPLATE.md`.
- Working tree is clean.
- Relevant tests or builds were run.
- Documentation is updated if user-facing behavior changed.
- No secrets or local runtime data are included.
- Known limitations are updated if the change affects release readiness.
- Screenshots hide API keys and private document contents.
