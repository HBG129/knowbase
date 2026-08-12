$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot

function Fail($Message) {
  Write-Error $Message
  exit 1
}

function Read-File($RelativePath) {
  $path = Join-Path $repoRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path)) {
    Fail "Missing file: $RelativePath"
  }
  Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Assert-Contains($Content, $Needle, $Description) {
  if (-not $Content.Contains($Needle)) {
    Fail "Missing $Description."
  }
}

function Assert-NotContains($Content, $Needle, $Description) {
  if ($Content.Contains($Needle)) {
    Fail "Found forbidden $Description."
  }
}

$loginForm = Read-File "frontend\src\components\auth\login-form.tsx"
$registerForm = Read-File "frontend\src\components\auth\register-form.tsx"
$apiKeyDialog = Read-File "frontend\src\components\auth\api-key-dialog.tsx"
$rootLayout = Read-File "frontend\src\app\layout.tsx"
$i18nStore = Read-File "frontend\src\stores\i18n-store.ts"
$globalsCss = Read-File "frontend\src\app\globals.css"
$apiClient = Read-File "frontend\src\lib\api.ts"
$i18n = Read-File "frontend\src\lib\i18n.ts"

Assert-Contains $loginForm "REMEMBERED_EMAIL_KEY" "remembered-email storage key in login form"
Assert-Contains $loginForm "showPassword" "password visibility state in login form"
Assert-Contains $loginForm "auth.rememberEmail" "remember-email label in login form"
Assert-Contains $loginForm "auth.showPassword" "show-password label in login form"
Assert-Contains $loginForm "localStorage.setItem(REMEMBERED_EMAIL_KEY, email)" "remembered-email save behavior"
Assert-Contains $loginForm "localStorage.removeItem(REMEMBERED_EMAIL_KEY)" "remembered-email clear behavior"
Assert-NotContains $loginForm "JSON.stringify({ email, password })" "plaintext password persistence"
Assert-NotContains $loginForm "setPassword(parsed.password" "saved password hydration"

Assert-Contains $registerForm "showPassword" "password visibility state in register form"
Assert-Contains $registerForm "auth.showPassword" "show-password label in register form"
Assert-Contains $apiKeyDialog "apiKey.providerDataNotice" "provider data disclosure in API key dialog"

Assert-Contains $rootLayout "function isAuthPath" "shared auth-route matcher"
Assert-Contains $rootLayout "isAuthPath(pathname)" "trailing-slash-safe auth-route matching"
Assert-Contains $i18nStore "hydrateLanguage" "client-side language hydration action"
Assert-Contains $rootLayout "hydrateLanguage();" "language hydration after mount"

Assert-Contains $globalsCss "::selection" "global text selection style"
Assert-Contains $globalsCss "input::selection" "input text selection style"
Assert-Contains $globalsCss "textarea::selection" "textarea text selection style"
Assert-Contains $globalsCss "--selection-bg" "high-contrast selection token"

Assert-Contains $apiClient 'localizedMessage("api.networkError")' "localized network error message"
Assert-Contains $apiClient "catch (error)" "network error handling"
Assert-Contains $apiClient "async function refreshAccessToken" "access-token refresh helper"
Assert-Contains $apiClient '"/api/auth/refresh"' "refresh-token API call"
Assert-Contains $apiClient "res.status === 401" "expired access-token retry condition"
Assert-Contains $apiClient "refreshPromise" "concurrent refresh deduplication"

Assert-Contains $i18n '"auth.rememberEmail"' "remember-email translation"
Assert-Contains $i18n '"auth.showPassword"' "show-password translation"
Assert-Contains $i18n '"auth.hidePassword"' "hide-password translation"
Assert-Contains $i18n '"api.networkError"' "network-error translation"

Write-Output "Auth UX checks passed."
