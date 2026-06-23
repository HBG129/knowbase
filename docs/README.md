# KnowBase Documentation

Use this index to find the right document quickly.

## Customer Documents

- `customer-quick-start.md` - target first-run flow for packaged Windows customers.
- `customer-data-and-privacy.md` - local data location, privacy notes, backup, restore, and uninstall data handling.
- `customer-troubleshooting.md` - customer-facing troubleshooting steps for install, startup, API key, upload, and chat issues.
- `customer-beta-test-plan.md` - controlled beta criteria, tester tasks, feedback format, and exit criteria.
- `privacy-notice-draft.md` - tester-facing privacy notice draft for local data, provider calls, and support boundaries.
- `known-limitations.md` - current limitations before a public customer release.
- `demo-data\` - synthetic files for safe screenshots, demos, and release validation.
- `assets\` - final README and release screenshots or GIFs.

## Release And Packaging

- `architecture.md` - system structure, runtime modes, data flow, storage, and packaging boundaries.
- `project-status.md` - current progress, verified items, blockers, and next required checks.
- `roadmap.md` - release-focused path from pre-release packaging to customer beta.
- `release-readiness-checklist.md` - required checks before publishing a customer installer.
- `clean-machine-validation.md` - clean Windows install validation checklist.
- `release-process.md` - release workflow from verification to GitHub Release publishing.
- `release-notes-template.md` - copy-ready GitHub Release notes template.
- `demo-assets.md` - screenshot, GIF, and demo-script guidance for README and releases.
- `desktop-build-troubleshooting.md` - Windows desktop packaging prerequisites and MSVC troubleshooting.
- `..\scripts\check-code-signature.ps1` - installer Authenticode status check for release validation.

## Support

- `support-runbook.md` - safe support workflow for customer issues without collecting secrets or private data.
- `..\scripts\collect-support-info.ps1` - local support report script for installation and startup triage.
- `..\scripts\remove-local-data.ps1` - dry-run-first local data removal script for uninstall, reinstall, or privacy cleanup.

## Design And Planning Records

- `superpowers\specs\` - design notes for larger changes.
- `superpowers\plans\` - implementation plans and verification notes.

## Security

See the root-level `SECURITY.md` before handling API keys, local databases, uploaded documents, logs, or screenshots.
