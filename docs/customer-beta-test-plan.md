# Customer Beta Test Plan

Use this plan before inviting real users to test a KnowBase Windows installer.

Customer beta is not the same as public release. The goal is to validate whether a small number of users can complete the main workflow and report issues without exposing private data.

## Entry Criteria

Do not start customer beta until these are true:

- GitHub Actions produces a Windows desktop installer artifact.
- `docs\clean-machine-validation.md` has passed on at least one clean Windows machine or VM.
- `docs\release-readiness-checklist.md` has no unresolved blocker for basic install, launch, upload, chat, and shutdown.
- `docs\customer-quick-start.md` matches the installer experience.
- `docs\customer-troubleshooting.md` and `docs\support-runbook.md` are ready for tester issues.
- Known limitations are listed in `docs\known-limitations.md`.

## Tester Profile

Use a small tester group first:

- 2 to 5 trusted users,
- Windows 10 or later,
- comfortable installing a test build,
- able to use a personal LLM provider key,
- willing to test with non-sensitive documents.

Do not use customer beta with regulated, confidential, or production business documents until API key storage, privacy notice, and release policy are reviewed.

## Test Package

Each tester should receive:

- installer filename,
- installer SHA256,
- release notes,
- `docs\customer-quick-start.md`,
- `docs\customer-troubleshooting.md`,
- known limitations,
- clear privacy warning not to upload private documents during beta.

## Required Test Tasks

Each tester should validate:

1. Install KnowBase without Python, Node.js, Rust, Git, or source code.
2. Launch KnowBase from the installed shortcut.
3. Register a local account.
4. Create a knowledge base.
5. Configure an LLM provider key.
6. Upload at least one non-sensitive PDF, Word, Markdown, TXT, or CSV file.
7. Ask a question and confirm the answer has citations.
8. Reopen a recent conversation.
9. Delete a conversation and confirm the in-app confirmation flow.
10. Close KnowBase and confirm the app exits normally.

## Feedback Format

Ask testers to report:

- Windows version,
- installer filename,
- KnowBase version or release tag,
- task that failed,
- expected behavior,
- actual behavior,
- non-sensitive screenshot or error text,
- whether `docs\customer-troubleshooting.md` helped.

For install, launch, backend, or health check failures, ask testers to run:

```powershell
.\scripts\collect-support-info.ps1
```

They may attach the generated Markdown report after checking it for private details.

## Blockers

Block customer beta if any of these happen:

- installer requires developer tools,
- app cannot launch,
- backend does not start automatically,
- login or registration fails for a clean install,
- document upload fails for all supported formats,
- chat cannot return cited answers with a valid provider key,
- API keys or document contents appear in visible logs,
- app leaves orphan backend processes after exit,
- support requires private databases or uploaded documents to diagnose common failures.

## Exit Criteria

Customer beta can move toward a public portfolio release when:

- at least 2 testers complete the required tasks,
- no blocker remains open,
- release notes include the tested installer name and SHA256,
- known limitations are updated,
- support issues are reproducible with non-sensitive files,
- clean-machine validation evidence is recorded in a GitHub `Release validation` issue.
