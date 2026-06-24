# Release Notes Template

Use this template when publishing a GitHub Release for KnowBase.

Copy the sections below into the release body and replace every bracketed value before publishing.

````markdown
# KnowBase v[version]

Private AI knowledge workspace for local documents.

## Highlights

- Windows desktop app packaging milestone.
- Local knowledge bases for PDF, Word, Markdown, TXT, and CSV files.
- RAG answers with source citations.
- Recent conversations, guided empty states, and in-app confirmations.

## Who This Release Is For

This release is intended for:

- users testing KnowBase on Windows,
- reviewers evaluating the AI knowledge-base workflow,
- developers validating desktop packaging and local runtime behavior.

This release is not intended for:

- production enterprise deployment,
- unattended installation at scale,
- environments that require code signing or automatic updates.

## Requirements

- Windows 10 or later.
- Internet access for LLM API calls.
- Customer-provided LLM API key unless a system fallback key is configured.
- Permission to store local app data under the Windows user profile.

## Installer

Artifact:

```text
[installer file name]
```

SHA256:

```text
[installer sha256]
```

Code signature:

```text
Status: [Valid/NotSigned/Unknown]
Signer: [signer subject or blank]
```

Expected local data directory:

```text
%APPDATA%\KnowBase
```

## First Run

1. Install and launch KnowBase.
2. Register a local account.
3. Create a knowledge base.
4. Upload one supported document.
5. Add an LLM API key if prompted.
6. Ask a question and check that the answer includes citations.

## Verification

- Clean Windows install: [passed/failed/not tested]
- Backend auto-start: [passed/failed/not tested]
- Register and login: [passed/failed/not tested]
- PDF upload and chat: [passed/failed/not tested]
- Word upload and chat: [passed/failed/not tested]
- Markdown upload and chat: [passed/failed/not tested]
- TXT upload and chat: [passed/failed/not tested]
- CSV upload and chat: [passed/failed/not tested]
- App close process cleanup: [passed/failed/not tested]
- Installer preinstall process cleanup: [passed/failed/not tested]
- Local data backup dry-run: [passed/failed/not tested]
- Local data restore dry-run: [passed/failed/not tested]
- Local data removal dry-run: [passed/failed/not tested]

## Known Limitations

- Code signature status for this installer: [Valid/NotSigned/Unknown]
- Auto-update is not configured yet.
- Enterprise deployment policy is not finalized.
- Local desktop packaging requires Microsoft C++ Build Tools when building outside GitHub Actions.
- Installer hooks are configured to stop `KnowBase.exe` and `KnowBaseBackend.exe` before overwrite, but upgrade behavior must still be validated on a clean Windows machine or VM.

## Security And Privacy

- Do not upload private customer documents when reporting issues.
- Do not share API keys, `.env` files, local databases, or `%APPDATA%\KnowBase`.
- See `SECURITY.md` for sensitive-data handling rules.

## Related Documentation

- `docs\customer-quick-start.md`
- `docs\customer-data-and-privacy.md`
- `docs\known-limitations.md`
- `docs\release-process.md`
- `docs\release-readiness-checklist.md`
````

Before publishing, confirm the release commit is pushed and the installer artifact has been downloaded and tested from GitHub, not only from a local build folder.
