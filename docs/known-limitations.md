# Known Limitations

This document lists current KnowBase limitations before a public customer release.

## Installer And Desktop Packaging

- A customer Windows installer has not been released yet.
- The Tauri desktop build is currently blocked on this machine until Microsoft C++ Build Tools provides `cl.exe` and `link.exe`.
- Code signing, installer metadata, and auto-update flow are not finalized.
- Clean-machine installation still needs to be verified on a Windows machine without Python, Node.js, Rust, or Git.

## Runtime Requirements

- Customers need internet access for LLM and embedding calls.
- Customers need a supported LLM provider key unless the distributed build includes a system fallback key.
- Provider behavior, rate limits, cost, privacy terms, and regional availability depend on the customer's selected provider.

## Data And Security

- Local data is stored under `%APPDATA%\KnowBase` in the desktop runtime.
- Uploaded documents and the SQLite database remain local unless content is sent to the configured LLM provider for answering or embeddings.
- Saved API keys are encrypted before being stored in the local application database. Moving secrets to the Windows credential store is still planned.
- Local database encryption is not implemented yet.
- Backup, restore, and uninstall data removal are documented, but not automated in the final installer yet.

## Product Scope

- OAuth login is not implemented.
- Knowledge base sharing links are not implemented.
- Reranker-based retrieval reordering is not implemented.
- Team or enterprise administration workflows are not finalized.
- Offline LLM inference is not included.

## Operational Readiness

- `docs\privacy-notice-draft.md` exists for testers, but final enterprise privacy notice and in-app legal copy are not finalized.
- Support workflows and a non-sensitive support info report script are available for install and startup triage.
- Production release notes should be created for every published installer.
- Public release should wait until the release readiness checklist passes.
