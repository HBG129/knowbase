param(
  [Parameter(Mandatory = $true)]
  [string]$ZipPath,

  [string]$ExpectedSha256 = "",

  [string]$Version = "0.1.0-rc.1",

  [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutputDir) {
  $workspaceRoot = Split-Path -Parent $repoRoot
  $OutputDir = Join-Path $workspaceRoot "artifacts\knowbase-release"
}

$zip = Resolve-Path -LiteralPath $ZipPath -ErrorAction SilentlyContinue
if (-not $zip) {
  Fail "Release artifact ZIP was not found: $ZipPath"
}

& (Join-Path $PSScriptRoot "check-release-artifact.ps1") -ZipPath $zip.Path -ExpectedSha256 $ExpectedSha256

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($zip.Path)
try {
  $installer = @(
    $archive.Entries |
      Where-Object { $_.FullName -match '(^|/|\\)KnowBase_.*_x64-setup\.exe$' -and $_.Length -gt 0 }
  )[0]

  $installerPath = Join-Path $OutputDir (Split-Path -Leaf $installer.FullName)
  [System.IO.Compression.ZipFileExtensions]::ExtractToFile($installer, $installerPath, $true)
}
finally {
  $archive.Dispose()
}

$zipHash = Get-FileHash -Algorithm SHA256 -LiteralPath $zip.Path
$installerHash = Get-FileHash -Algorithm SHA256 -LiteralPath $installerPath
$installerSignature = Get-AuthenticodeSignature -LiteralPath $installerPath
$signatureStatus = [string]$installerSignature.Status
$signatureSigner = ""
if ($installerSignature.SignerCertificate) {
  $signatureSigner = [string]$installerSignature.SignerCertificate.Subject
}
$checksumPath = Join-Path $OutputDir "SHA256SUMS.txt"
$summaryPath = Join-Path $OutputDir "RELEASE_ARTIFACTS.md"
$releaseNotesPath = Join-Path $OutputDir "RELEASE_NOTES_DRAFT.md"
$validationIssuePath = Join-Path $OutputDir "RELEASE_VALIDATION_ISSUE_DRAFT.md"
$installerName = Split-Path -Leaf $installerPath
$zipName = Split-Path -Leaf $zip.Path

$checksums = @(
  "$($installerHash.Hash)  $installerName"
  "$($zipHash.Hash)  $zipName"
)
Set-Content -LiteralPath $checksumPath -Value $checksums -Encoding ASCII

$summary = @(
  '# KnowBase Release Artifacts'
  ''
  "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
  ''
  '## Files'
  ''
  "- Installer: ``$installerName``"
  "- Source ZIP artifact: ``$zipName``"
  '- Checksums: `SHA256SUMS.txt`'
  ''
  '## SHA256'
  ''
  '```text'
  $checksums
  '```'
  ''
  '## Code Signature'
  ''
  "- Status: ``$signatureStatus``"
  "- Signer: ``$signatureSigner``"
  ''
  '## Next Step'
  ''
  'Install the setup executable on a clean Windows machine and follow `docs\clean-machine-validation.md`.'
)
Set-Content -LiteralPath $summaryPath -Value $summary -Encoding ASCII

$releaseNotes = @(
  "# KnowBase v$Version"
  ''
  'Private AI knowledge workspace for local documents.'
  ''
  '## Highlights'
  ''
  '- Windows desktop app packaging milestone.'
  '- Local knowledge bases for PDF, Word, Markdown, TXT, and CSV files.'
  '- RAG answers with source citations.'
  '- Recent conversations, guided empty states, and in-app confirmations.'
  ''
  '## Who This Release Is For'
  ''
  'This release is intended for:'
  ''
  '- users testing KnowBase on Windows,'
  '- reviewers evaluating the AI knowledge-base workflow,'
  '- developers validating desktop packaging and local runtime behavior.'
  ''
  'This release is not intended for:'
  ''
  '- production enterprise deployment,'
  '- unattended installation at scale,'
  '- environments that require code signing or automatic updates.'
  ''
  '## Requirements'
  ''
  '- Windows 10 or later.'
  '- Internet access for LLM API calls.'
  '- Customer-provided LLM API key unless a system fallback key is configured.'
  '- Permission to store local app data under the Windows user profile.'
  ''
  '## Installer'
  ''
  'Artifact:'
  ''
  '```text'
  $installerName
  '```'
  ''
  'SHA256:'
  ''
  '```text'
  $installerHash.Hash
  '```'
  ''
  'Code signature status:'
  ''
  '```text'
  $signatureStatus
  '```'
  ''
  'Signer:'
  ''
  '```text'
  $signatureSigner
  '```'
  ''
  'Expected local data directory:'
  ''
  '```text'
  '%APPDATA%\KnowBase'
  '```'
  ''
  '## First Run'
  ''
  '1. Install and launch KnowBase.'
  '2. Register a local account.'
  '3. Create a knowledge base.'
  '4. Upload one supported document.'
  '5. Add an LLM API key if prompted.'
  '6. Ask a question and check that the answer includes citations.'
  ''
  '## Verification'
  ''
  '- Clean Windows install: not tested'
  '- Backend auto-start: not tested'
  '- Register and login: not tested'
  '- PDF upload and chat: not tested'
  '- Word upload and chat: not tested'
  '- Markdown upload and chat: not tested'
  '- TXT upload and chat: not tested'
  '- CSV upload and chat: not tested'
  '- App close process cleanup: not tested'
  '- Local data backup dry-run: not tested'
  '- Local data restore dry-run: not tested'
  '- Local data removal dry-run: not tested'
  ''
  '## Known Limitations'
  ''
  "- Code signature status for this installer: $signatureStatus"
  '- Auto-update is not configured yet.'
  '- Enterprise deployment policy is not finalized.'
  '- Local desktop packaging requires Microsoft C++ Build Tools when building outside GitHub Actions.'
  ''
  '## Security And Privacy'
  ''
  '- Do not upload private customer documents when reporting issues.'
  '- Do not share API keys, `.env` files, local databases, or `%APPDATA%\KnowBase`.'
  '- See `SECURITY.md` for sensitive-data handling rules.'
  ''
  '## Related Documentation'
  ''
  '- `docs\customer-quick-start.md`'
  '- `docs\customer-data-and-privacy.md`'
  '- `docs\known-limitations.md`'
  '- `docs\release-process.md`'
  '- `docs\release-readiness-checklist.md`'
)
Set-Content -LiteralPath $releaseNotesPath -Value $releaseNotes -Encoding ASCII

$validationIssue = @(
  "# Release Validation: KnowBase v$Version"
  ''
  'Use this as a working note when filling the GitHub `Release validation` issue form.'
  ''
  '## Release Version'
  ''
  '```text'
  $Version
  '```'
  ''
  '## Installer Artifact'
  ''
  '```text'
  $installerName
  '```'
  ''
  '## Installer SHA256'
  ''
  '```text'
  $installerHash.Hash
  '```'
  ''
  '## Code Signature'
  ''
  '```text'
  "Status: $signatureStatus"
  "Signer: $signatureSigner"
  '```'
  ''
  '## Clean Machine Baseline'
  ''
  '- [ ] Test machine does not have Python installed.'
  '- [ ] Test machine does not have Node.js installed.'
  '- [ ] Test machine does not have Rust installed.'
  '- [ ] Test machine does not have Git installed.'
  '- [ ] Test machine does not have the KnowBase source checkout.'
  '- [ ] Test machine has internet access.'
  '- [ ] Test machine has a valid LLM provider API key for testing.'
  ''
  '## Install And Launch'
  ''
  '- [ ] Installer runs without developer tools.'
  '- [ ] KnowBase launches from Start Menu or desktop shortcut.'
  '- [ ] Desktop app starts the backend automatically.'
  '- [ ] App opens without a developer terminal.'
  '- [ ] App stores runtime data under `%APPDATA%\KnowBase`.'
  '- [ ] `scripts\check-installed-app.ps1` report was generated and reviewed.'
  ''
  '## First-Run Flow'
  ''
  '- [ ] User registration succeeds.'
  '- [ ] Login succeeds.'
  '- [ ] Knowledge base creation succeeds.'
  '- [ ] API key settings accepts a valid provider key.'
  '- [ ] PDF upload and cited chat answer work.'
  '- [ ] Word upload and cited chat answer work.'
  '- [ ] Markdown upload and cited chat answer work.'
  '- [ ] TXT upload and cited chat answer work.'
  '- [ ] CSV upload and cited chat answer work.'
  '- [ ] Recent conversations reopen correctly.'
  '- [ ] Conversation deletion uses in-app confirmation.'
  ''
  '## Shutdown, Security, And Privacy'
  ''
  '- [ ] Closing the app stops the backend process.'
  '- [ ] Relaunch keeps account, knowledge base, documents, and conversations.'
  '- [ ] No API key appears in visible logs.'
  '- [ ] No document content appears in visible logs.'
  '- [ ] No `.env`, database, uploaded document, or `%APPDATA%\KnowBase` folder is attached to the issue.'
  '- [ ] Local data backup dry-run was reviewed without sharing the backup ZIP.'
  '- [ ] Local data restore dry-run was reviewed when reinstall or migration was tested.'
  '- [ ] Local data removal dry-run was reviewed before any confirmed deletion.'
  ''
  '## Failures Or Notes'
  ''
  '```text'
  '- Failed check:'
  '- Windows version:'
  '- Non-sensitive error:'
  '```'
  ''
  '## Release Decision'
  ''
  '- [ ] Block release'
  '- [ ] Ready for limited tester release'
  '- [ ] Ready for public release'
)
Set-Content -LiteralPath $validationIssuePath -Value $validationIssue -Encoding ASCII

Write-Output "Release package prepared."
Write-Output "Output: $OutputDir"
Write-Output "Installer: $installerPath"
Write-Output "Checksums: $checksumPath"
Write-Output "Summary: $summaryPath"
Write-Output "Release notes draft: $releaseNotesPath"
Write-Output "Release validation issue draft: $validationIssuePath"
