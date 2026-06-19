# Summary

Describe what changed and why.

## Type

- [ ] Bug fix
- [ ] Feature
- [ ] Documentation
- [ ] CI / packaging
- [ ] Security / privacy
- [ ] Refactor

## Verification

List the checks you ran:

- [ ] Frontend build: `cd frontend && npm run build`
- [ ] Backend tests: `cd backend && .\.venv\Scripts\python.exe -m pytest tests -q`
- [ ] Desktop prerequisites: `.\check-desktop-prereqs.bat`
- [ ] Desktop package: `.\package-desktop.bat`
- [ ] PowerShell script syntax: `.\scripts\check-powershell-scripts.ps1`
- [ ] Manual GitHub Actions workflow: `Desktop Package`
- [ ] Documentation-only change; command verification not required

## Customer Impact

- [ ] No customer-facing behavior changed
- [ ] Customer-facing behavior changed and docs were updated
- [ ] Release readiness or known limitations were updated

## Security And Privacy

- [ ] No secrets, `.env` files, uploaded documents, local databases, or `%APPDATA%\KnowBase` files are included
- [ ] Logs and screenshots hide API keys, tokens, and private document contents
- [ ] Security-sensitive changes were checked against `SECURITY.md`

## Notes

Add anything reviewers should know.
