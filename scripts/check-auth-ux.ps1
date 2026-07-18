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

$loginForm = Read-File "frontend\src\components\auth\login-form.tsx"
$registerForm = Read-File "frontend\src\components\auth\register-form.tsx"
$rootLayout = Read-File "frontend\src\app\layout.tsx"
$i18nStore = Read-File "frontend\src\stores\i18n-store.ts"
$globalsCss = Read-File "frontend\src\app\globals.css"
$apiClient = Read-File "frontend\src\lib\api.ts"
$i18n = Read-File "frontend\src\lib\i18n.ts"

Assert-Contains $loginForm "REMEMBER_LOGIN_KEY" "remember-password storage key in login form"
Assert-Contains $loginForm "showPassword" "password visibility state in login form"
Assert-Contains $loginForm "auth.rememberPassword" "remember-password label in login form"
Assert-Contains $loginForm "auth.showPassword" "show-password label in login form"
Assert-Contains $loginForm "localStorage.setItem(REMEMBER_LOGIN_KEY" "remember-password save behavior"
Assert-Contains $loginForm "localStorage.removeItem(REMEMBER_LOGIN_KEY" "remember-password clear behavior"

Assert-Contains $registerForm "showPassword" "password visibility state in register form"
Assert-Contains $registerForm "auth.showPassword" "show-password label in register form"

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

Assert-Contains $i18n '"auth.rememberPassword"' "remember-password translation"
Assert-Contains $i18n '"auth.showPassword"' "show-password translation"
Assert-Contains $i18n '"auth.hidePassword"' "hide-password translation"
Assert-Contains $i18n '"api.networkError"' "network-error translation"

Write-Output "Auth UX checks passed."
