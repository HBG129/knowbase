# Known Limitations

This document lists current KnowBase limitations before a public customer release.

## Installer And Desktop Packaging

- A customer Windows installer has not been released yet.
- The controlled tester candidate is `v0.1.0-rc.1`, with `v0.1.0` selected as the GA target after all release gates pass.
- Code signing and the auto-update flow are not finalized.
- A fixed-runtime installer has rendered and passed core API smoke checks in Windows Sandbox without Python, Node.js, Rust, or Git. The exact current CI artifact still needs close, orphan-process cleanup, uninstall, and real-provider RAG/Analysis validation.

## Runtime Requirements

- Customers need internet access for LLM and embedding calls.
- Customers need a supported LLM provider key unless the distributed build includes a system fallback key.
- Provider behavior, rate limits, cost, privacy terms, and regional availability depend on the customer's selected provider.

## Data And Security

- Local data is stored under `%APPDATA%\KnowBase` in the desktop runtime.
- Uploaded documents and the SQLite database remain local unless content is sent to the configured LLM provider for answering or embeddings.
- In the packaged Windows desktop runtime, saved API keys are stored through Windows Credential Manager and the local database stores only a credential reference. Non-desktop fallback modes use encrypted local database storage.
- Local database encryption is not implemented yet.
- Backup, restore, and uninstall data removal are documented, but not automated in the final installer yet.

## Product Scope

- OAuth login is not implemented.
- Knowledge base sharing links are not implemented.
- Reranker-based retrieval reordering is not implemented.
- CSV data analysis is limited to completed CSV uploads. Excel files, multi-table joins, scheduled reports, and offline analysis models are not implemented.
- CSV data analysis uses generated read-only SQL and LLM-written summaries. Customers should review results before using them for business-critical decisions.
- Team or enterprise administration workflows are not finalized.
- Offline LLM inference is not included.

## Operational Readiness

- `docs\privacy-notice-draft.md` exists for testers, but final enterprise privacy notice and in-app legal copy are not finalized.
- Support workflows and a non-sensitive support info report script are available for install and startup triage.
- Production release notes should be created for every published installer.
- Public release should wait until the release readiness checklist passes.
