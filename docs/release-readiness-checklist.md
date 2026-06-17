# Release Readiness Checklist

Use this checklist before publishing a KnowBase Windows installer for customers.

## Current Release Decision

KnowBase is not customer-release ready until all required items below pass on a clean Windows machine.

Required release target:

```text
A customer can install KnowBase, launch it, create an account, create a knowledge base, upload a document, ask a question, and receive an answer without installing Python, Node.js, Rust, or Git.
```

## Build Machine Requirements

The build machine must have:

- Node.js and npm
- Rust and Cargo
- Microsoft C++ Build Tools with `Desktop development with C++`
- Python 3.12 virtual environment for backend packaging
- Project dependencies installed
- Valid LLM API key for runtime testing

Run:

```powershell
.\check-desktop-prereqs.bat
.\package-desktop.bat
```

The release build is blocked if `cl.exe` or `link.exe` is missing. See:

```text
docs\desktop-build-troubleshooting.md
```

## Functional Smoke Test

Run these checks before publishing a build:

- App launches from the installed shortcut.
- Backend starts automatically when the desktop app opens.
- Health endpoint returns `{"status":"ok"}`.
- User can register and log in.
- User can create a knowledge base.
- User can upload PDF, Word, Markdown, TXT, and CSV files.
- Uploaded documents appear in the knowledge base document list.
- Chat input is enabled only when the selected knowledge base has usable documents.
- AI answer returns with source citations.
- Missing LLM API key shows a useful error and a direct API Key Settings action.
- Recent conversations appear and reopen correctly.
- Conversation deletion uses the in-app confirmation flow.
- App closes without leaving orphan backend processes.

## Clean Machine Test

Test the installer on a Windows machine or virtual machine that does not have the development stack installed.

The clean machine must not require:

- Python
- Node.js
- Rust
- Git
- Local project source code

The clean machine may still require:

- Internet access
- A valid LLM provider API key
- Permission to store local app data under the user's profile

## Customer-Facing Requirements

Before public release, confirm:

- App name and icon are final.
- Installer name is clear and versioned.
- README has a customer installation section.
- README explains customer API key requirements and first-run setup.
- The app shows useful errors when no LLM API key is configured.
- Local data location is documented in `docs\customer-data-and-privacy.md`.
- Uninstall behavior and manual data removal are documented in `docs\customer-data-and-privacy.md`.
- Known limitations are listed in `docs\known-limitations.md`.

## Security And Privacy

Before release, confirm:

- `.env` is never bundled with secrets.
- Local database and uploaded files are not committed.
- JWT secret is generated for production use.
- API keys are stored in a customer-controlled location.
- CORS is not left open for public network exposure.
- Logs do not expose API keys or document contents.

## Release Notes Template

Use this structure for each GitHub release:

```markdown
# KnowBase vX.Y.Z

## Highlights

- Desktop installer for Windows.
- Local knowledge bases for private documents.
- RAG answers with source citations.

## Requirements

- Windows 10 or later.
- Internet access for LLM API calls.
- Customer-provided LLM API key.

## Known Limitations

- App signing is not configured yet.
- Auto-update is not configured yet.
- Enterprise deployment policy is not finalized.

## Verification

- Clean Windows install: passed/failed.
- PDF upload and chat: passed/failed.
- Word upload and chat: passed/failed.
- App close process cleanup: passed/failed.
```
