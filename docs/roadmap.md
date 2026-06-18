# Roadmap

KnowBase is moving toward a customer-installable Windows desktop AI knowledge base.

This roadmap is intentionally short and release-focused. It tracks what must happen before the app can be handed to real users with reasonable confidence.

## Current Phase: Pre-Release Desktop Packaging

Goal:

```text
A Windows user can install KnowBase, launch it, upload documents, ask cited questions, and close the app without installing developer tools.
```

Current focus:

- backend executable packaging,
- Tauri desktop shell,
- local backend startup and shutdown,
- clean-machine installer validation,
- customer-facing documentation,
- safe demo and release assets.

## Next Milestone: Internal Alpha

Internal alpha means the app can be tested by the developer or a trusted reviewer on a clean Windows machine.

Required:

- Windows installer artifact produced by local build or GitHub Actions.
- Desktop package workflow runs on relevant `main` pushes or manual dispatch.
- Clean Windows machine test passes.
- Backend starts automatically from the desktop shell.
- App closes without orphan backend processes.
- Demo files from `docs\demo-data` upload and answer with citations.
- README includes real screenshots or a short GIF from `docs\assets`.

## Next Milestone: Public Portfolio Release

Public portfolio release means the GitHub project is strong enough for recruiters, interviewers, and technical reviewers.

Required:

- README clearly shows product value, architecture, setup, and verification.
- Screenshots or GIFs demonstrate the main workflow.
- Release notes use `docs\release-notes-template.md`.
- Known limitations are explicit.
- CI is passing.
- No secrets, private documents, local databases, or generated build outputs are committed.

## Next Milestone: Customer Beta

Customer beta means a small number of real users can try the app with clear limitations.

Required:

- Installer is versioned and attached to a GitHub Release.
- Customer quick start is accurate.
- Local data and uninstall behavior are documented.
- API key handling is reviewed.
- Error messages guide users when provider keys, network, or file processing fail.
- Support runbook is usable without collecting private files by default.

## Later Work

These are important, but not required for the next release:

- OS credential storage for API keys.
- Code signing.
- Auto-update.
- Installer customization.
- OAuth login.
- Knowledge base sharing links.
- Reranker support for retrieval quality.
- Enterprise deployment policy.

## Non-Goals For The Next Release

- Multi-tenant hosted SaaS.
- Public web deployment.
- Enterprise SSO.
- Cloud document synchronization.
- Billing.

These would materially change the architecture and should be planned separately.
