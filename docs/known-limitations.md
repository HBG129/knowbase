# Known Limitations

This document lists current KnowBase limitations before a public customer release.

## Installer And Desktop Packaging

- A customer Windows installer has not been released yet.
- The controlled tester candidate is `v0.1.0-rc.1`, with `v0.1.0` selected as the GA target after all release gates pass.
- The protected signed-release workflow is implemented, but no production code-signing certificate is configured yet. The auto-update flow is not finalized.
- Dependency versions are committed in backend, frontend, and Rust lockfiles. The signed-candidate workflow includes dependency manifests, SHA256 checksums, and GitHub provenance attestations.
- The exact fixed-runtime CI installer passed automated offline Windows Sandbox and real-provider RAG/Analysis validation. The current candidate remains unsigned, so Windows may show SmartScreen or publisher warnings until a valid code-signing certificate is integrated.

## Runtime Requirements

- Customers need internet access for LLM and embedding calls.
- Customers need a supported LLM provider key unless the distributed build includes a system fallback key.
- Provider behavior, rate limits, cost, privacy terms, and regional availability depend on the customer's selected provider.

## Data And Security

- Local data is stored under `%APPDATA%\KnowBase` in the desktop runtime.
- Uploaded documents and the SQLite database remain local unless content is sent to the configured LLM provider for answering or embeddings.
- In the packaged Windows desktop runtime, saved API keys are stored through Windows Credential Manager and the local database stores only a credential reference. Non-desktop fallback modes use encrypted local database storage.
- Local database encryption is not implemented yet.
- Uninstall intentionally preserves customer data. Backup, restore, and complete dry-run-first removal are provided through support tools rather than an installer deletion option.

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
