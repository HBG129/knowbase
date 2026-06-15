# KnowBase engineering hardening design

## Goal

Add a small engineering safety layer around KnowBase so future changes are easier to verify and publish.

## Scope

- Add GitHub Actions CI for frontend build and backend tests.
- Add `.gitattributes` to keep repository line endings predictable on Windows.
- Replace the broken mojibake text in `start-utf8.bat` with readable ASCII output.
- Update README with CI and Windows verification guidance.

## Out of scope

- Tauri or Electron packaging.
- Product feature changes.
- Frontend visual redesign.
- Deployment automation.

## Design

Use two independent CI jobs: one for the Next.js frontend and one for the FastAPI backend. The backend job uses Python 3.12, installs `backend[dev]`, and runs pytest with a workspace-local temp directory so Windows temp permission issues do not leak into the documented workflow. The frontend job uses Node 20 and `npm ci`.

Keep `start-utf8.bat` ASCII-only. This avoids another encoding failure in Windows consoles while preserving the same behavior: start backend, start frontend, open the browser, and stop child windows on exit.

## Verification

- `npm run build` from `frontend`
- backend pytest with workspace-local temp directory
- `git status` clean after commit
