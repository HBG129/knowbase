# Release Process

Use this process when preparing a KnowBase Windows desktop release.

Do not publish a customer installer until `docs\release-readiness-checklist.md` passes.

## 1. Confirm The Build Machine

Run from the repository root:

```powershell
.\check-desktop-prereqs.bat
```

The build machine must have:

- Node.js and npm
- Rust and Cargo
- Microsoft C++ Build Tools with `Desktop development with C++`
- Python 3.12 backend environment
- backend dependencies installed
- frontend dependencies installed

If `cl.exe` or `link.exe` is missing, stop and fix the Visual Studio Build Tools installation first.

## 2. Run Verification

Run repository preflight checks:

```powershell
.\scripts\check-release-preflight.ps1
```

Run backend tests:

```powershell
cd backend
.\.venv\Scripts\python.exe -m pytest
```

Run frontend build:

```powershell
cd frontend
npm run build
```

Return to the repository root before packaging:

```powershell
cd ..
```

## 3. Build The Desktop Package

Run:

```powershell
.\package-desktop.bat
```

Expected output location:

```text
frontend\src-tauri\target\release\bundle
```

Verify generated artifacts:

```powershell
.\scripts\check-desktop-artifacts.ps1
```

Verify the packaged backend executable starts and responds to health checks:

```powershell
.\scripts\check-packaged-backend-health.ps1
```

Do not publish if packaging fails, if the generated bundle is missing, or if the artifact check fails.

Alternatively, run the manual GitHub Actions workflow:

```text
Desktop Package
```

This uses a GitHub-hosted Windows runner and can build without relying on the local machine's Visual Studio Build Tools installation.

The same workflow also runs automatically on pushes to `main` when backend, frontend, desktop packaging scripts, or the desktop workflow itself changes.

Expected GitHub Actions artifacts:

```text
KnowBaseBackend-<run number>
KnowBaseDesktop-Windows-<run number>
```

The desktop artifact must include the NSIS installer output from:

```text
frontend\src-tauri\target\release\bundle\nsis
```

If the workflow cannot find the backend executable or NSIS installer, the artifact verification step fails before upload.

After downloading the desktop artifact ZIP, verify it before installation:

```powershell
.\scripts\check-release-artifact.ps1 -ZipPath D:\Codex_AI_Workspace\artifacts\KnowBaseDesktop-Windows-3.zip
```

Prepare the files for a GitHub Release:

```powershell
.\scripts\prepare-release-package.ps1 -ZipPath D:\Codex_AI_Workspace\artifacts\KnowBaseDesktop-Windows-3.zip
```

The command blocks installers whose Authenticode status is not `Valid`. For explicitly approved unsigned validation or release builds, add `-AllowUnsigned` and ensure the generated release notes clearly disclose the unsigned status.

This creates:

```text
D:\Codex_AI_Workspace\artifacts\knowbase-release\KnowBase_0.1.0_x64-setup.exe
D:\Codex_AI_Workspace\artifacts\knowbase-release\SHA256SUMS.txt
D:\Codex_AI_Workspace\artifacts\knowbase-release\RELEASE_ARTIFACTS.md
D:\Codex_AI_Workspace\artifacts\knowbase-release\RELEASE_NOTES_DRAFT.md
D:\Codex_AI_Workspace\artifacts\knowbase-release\RELEASE_VALIDATION_ISSUE_DRAFT.md
```

Check the installer code signature:

```powershell
.\scripts\check-code-signature.ps1 -Path D:\Codex_AI_Workspace\artifacts\knowbase-release\KnowBase_0.1.0_x64-setup.exe
```

For explicitly approved unsigned validation or release builds, use `-AllowUnsigned` to record the signature state without failing, and disclose that status in the release notes.

### Signed customer candidate

The regular `Desktop Package` workflow intentionally produces an unsigned validation build. A customer-signed candidate must use the manual GitHub Actions workflow:

```text
Signed Windows Release Candidate
```

Run it only from `main`. Configure a protected GitHub Environment named `release-signing` with required reviewers and deployment branch restricted to `main`.

Environment secrets:

```text
WINDOWS_CERTIFICATE_BASE64
WINDOWS_CERTIFICATE_PASSWORD
```

Environment variable:

```text
WINDOWS_TIMESTAMP_URL
```

`WINDOWS_CERTIFICATE_BASE64` is the Base64 encoding of a PFX that contains an accessible private key and the Code Signing EKU (`1.3.6.1.5.5.7.3.3`). Never commit the PFX, Base64 value, password, or private key. Use the timestamp URL supplied by the certificate provider.

The protected workflow:

1. imports the PFX into the ephemeral runner's current-user certificate store,
2. validates certificate validity, private-key access, and Code Signing EKU,
3. signs and timestamps `KnowBaseBackend.exe` before it is embedded,
4. lets Tauri sign and timestamp the desktop executable and NSIS installer,
5. pins all three signatures to the same certificate thumbprint and requires a trusted timestamp,
6. removes the PFX and imported certificate even when a later step fails,
7. exports the locked backend and frontend CycloneDX SBOMs, a normalized Rust dependency manifest, and build metadata tied to the source commit,
8. includes every manifest in `SHA256SUMS.txt`, creates one exact release ZIP, and generates GitHub provenance attestations for both the signed installer and exact release ZIP,
9. generates a self-contained release package without using `-AllowUnsigned`.

Expected artifact:

```text
KnowBaseSignedRelease-<run number>.zip
```

It contains the signed installer, desktop bundle ZIP, support tools, SHA256 checksums, release notes draft, artifact summary, release-validation issue draft, `backend-sbom.cdx.json`, `frontend-sbom.cdx.json`, `rust-dependencies.json`, and `BUILD_METADATA.json`. Backend builds resolve from `backend\uv.lock`; frontend and Rust continue to use their committed lockfiles.

Verify the downloaded installer and exact release ZIP against their GitHub build provenance:

```powershell
gh attestation verify .\KnowBase_0.1.0_x64-setup.exe -R HBG129/knowbase
gh attestation verify .\KnowBaseSignedRelease-<run number>.zip -R HBG129/knowbase
```

An attestation links the artifact to its GitHub workflow and source commit; it does not replace Authenticode, dependency auditing, clean-machine validation, or the release approval gate. The workflow does not publish a GitHub Release; Issue #17 must record the final `Ready` decision first.

For a local certificate already installed in Windows, run:

```powershell
.\scripts\build-signed-release.ps1 `
  -CertificateThumbprint <40-character-thumbprint> `
  -TimestampUrl <provider-RFC3161-URL>
```

## 4. Test On A Clean Windows Machine

Install the generated package on a Windows machine or virtual machine without the development toolchain.

The clean machine must not require:

- Python
- Node.js
- Rust
- Git
- project source code

Validate the first-run flow in:

```text
docs\customer-quick-start.md
```

Record the clean-machine result with:

```text
docs\clean-machine-validation.md
```

For GitHub tracking, open a `Release validation` issue and paste the installer name and SHA256 from:

```text
D:\Codex_AI_Workspace\artifacts\knowbase-release\RELEASE_NOTES_DRAFT.md
```

In the release validation issue, record the signer or the unsigned approver, approval date, and exact release-notes disclosure. `-AllowUnsigned` applies only when the installer status is `NotSigned`; it does not permit invalid or untrusted signatures. Any other non-`Valid` status must keep the release blocked.

Use this local draft as the working checklist while testing:

```text
D:\Codex_AI_Workspace\artifacts\knowbase-release\RELEASE_VALIDATION_ISSUE_DRAFT.md
```

Extract `KnowBaseSupportTools.zip` into a folder named `support-tools`. After installing and launching the app on the clean machine, run from the folder that contains `support-tools`:

```powershell
cd .\support-tools
powershell -ExecutionPolicy Bypass -File .\check-installed-app.ps1
```

The report is written to `Desktop\KnowBaseValidation` by default and includes the installed executable version, signature status, installed executable path, and backend process path when available. Attach only the generated Markdown report if it contains no secrets or private document content.

## 5. Prepare Release Notes

Use the template in:

```text
docs\release-notes-template.md
```

Release notes must include:

- version,
- highlights,
- requirements,
- known limitations,
- verification results,
- installer artifact name.

If the release includes visible UI changes, prepare demo assets using:

```text
docs\demo-assets.md
```

## 6. Publish The GitHub Release

Before publishing:

- confirm the git working tree is clean,
- confirm the release commit is pushed,
- confirm `.\scripts\check-code-signature.ps1` reports `Valid`, or state clearly that the release is unsigned,
- attach the installer artifact,
- include release notes,
- include known limitations.

If code signing is not configured, state that clearly in the release notes.

## 7. Post-Release Checks

After publishing:

- download the release artifact from GitHub,
- install it on a clean Windows machine,
- launch the app,
- configure an API key,
- upload one test document,
- ask one question,
- close the app and confirm the backend exits.

Record the result in the release notes or release issue.
