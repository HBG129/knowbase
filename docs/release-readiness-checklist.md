# Release Readiness Checklist

Use this checklist before publishing a KnowBase Windows installer for customers.

## Current Release Decision

KnowBase is not customer-release ready until all required items below pass on a clean Windows machine.

Required release target:

```text
A customer can install KnowBase, launch it, create an account, create a knowledge base, upload documents and CSV files, ask cited questions, run CSV analysis, and receive useful results without installing Python, Node.js, Rust, or Git.
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
.\scripts\check-release-preflight.ps1
.\check-desktop-prereqs.bat
.\package-desktop.bat
.\scripts\check-desktop-artifacts.ps1
.\scripts\check-packaged-backend-health.ps1
```

The release build is blocked if `cl.exe` or `link.exe` is missing. See:

```text
docs\desktop-build-troubleshooting.md
```

If the local build machine is blocked, try the manual GitHub Actions workflow:

```text
Desktop Package
```

The workflow also runs automatically on relevant pushes to `main`.

Required workflow artifacts:

- `KnowBaseBackend-<run number>`
- `KnowBaseDesktop-Windows-<run number>`

The desktop workflow is not release-ready if either artifact is missing.

After downloading the desktop ZIP, verify the release artifact before installing it:

```powershell
.\scripts\check-release-artifact.ps1 -ZipPath D:\Codex_AI_Workspace\artifacts\KnowBaseDesktop-Windows-3.zip
```

After extracting or preparing the installer, verify its Authenticode status:

```powershell
.\scripts\check-code-signature.ps1 -Path D:\Codex_AI_Workspace\artifacts\knowbase-release\KnowBase_0.1.0_x64-setup.exe
```

`prepare-release-package.ps1` blocks a non-`Valid` signature by default. Use `-AllowUnsigned` only for an explicitly approved unsigned build whose release notes disclose that status.

The release validation issue must record either the valid signer and certificate thumbprint, or the unsigned approver, approval date, and exact release-notes disclosure. An invalid or undecided signature blocks release.

## Functional Smoke Test

Run these checks before publishing a build:

- App launches from the installed shortcut.
- Backend starts automatically when the desktop app opens.
- Health endpoint returns `{"status":"ok"}`.
- User can register and log in.
- User can create a knowledge base.
- User can upload PDF, Word, Markdown, TXT, and CSV files.
- User can use the CSV Analysis tab to preview data, ask a question, see a chart and summary, and reopen the analysis history.
- Uploaded documents appear in the knowledge base document list.
- Synthetic demo files from `docs\demo-data` upload and produce cited answers.
- Chat input is enabled only when the selected knowledge base has usable documents.
- AI answer returns with source citations.
- Missing LLM API key shows a useful error and a direct API Key Settings action.
- Recent conversations appear and reopen correctly.
- Conversation deletion uses the in-app confirmation flow.
- App closes without leaving orphan backend processes.

## Clean Machine Test

Test the installer on a Windows machine or virtual machine that does not have the development stack installed.

Use:

```text
docs\clean-machine-validation.md
```

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
- Installer code signature is valid, or the release validation issue records explicit unsigned approval and the release notes clearly state that the build is unsigned.
- README has a customer installation section.
- Documentation index is available in `docs\README.md`.
- Customer quick start is documented in `docs\customer-quick-start.md`.
- Customer beta testing is planned in `docs\customer-beta-test-plan.md`.
- Privacy notice draft is available in `docs\privacy-notice-draft.md`.
- Release process is documented in `docs\release-process.md`.
- README explains customer API key requirements and first-run setup.
- The app shows useful errors when no LLM API key is configured.
- Chinese and English interfaces cover the complete customer workflow, including authentication, knowledge bases, document upload, cited chat, API key settings, CSV Analysis, errors, and empty states.
- Switching languages does not cause hydration warnings, mixed-language controls, broken layouts, or untranslated accessibility labels on desktop or mobile viewports.
- Local data location is documented in `docs\customer-data-and-privacy.md`.
- Backup and restore scripts are documented in `docs\customer-data-and-privacy.md`.
- Uninstall behavior and manual data removal are documented in `docs\customer-data-and-privacy.md`.
- Known limitations are listed in `docs\known-limitations.md`.
- Release notes use `docs\release-notes-template.md`.
- README and release assets follow `docs\demo-assets.md`.

## Security And Privacy

Before release, confirm:

- `.env` is never bundled with secrets.
- Local database and uploaded files are not committed.
- JWT secret is generated for production use.
- API keys are stored in a customer-controlled location.
- CORS is not left open for public network exposure.
- Logs do not expose API keys or document contents.
- Backup, restore, and removal dry-runs do not expose local databases, uploaded documents, or API keys in shared support material.
- Support workflow is documented in `docs\support-runbook.md`.
- Support privacy boundaries are documented in `docs\privacy-notice-draft.md`.

## Release Notes

Use the standalone release notes template:

```text
docs\release-notes-template.md
```
