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

Assert-Contains $globalsCss "::selection" "global text selection style"
Assert-Contains $globalsCss "input::selection" "input text selection style"
Assert-Contains $globalsCss "textarea::selection" "textarea text selection style"
Assert-Contains $globalsCss "--selection-bg" "high-contrast selection token"

Assert-Contains $apiClient "NETWORK_ERROR_MESSAGE" "network error message constant"
Assert-Contains $apiClient "catch (error)" "network error handling"

Assert-Contains $i18n '"auth.rememberPassword"' "remember-password translation"
Assert-Contains $i18n '"auth.showPassword"' "show-password translation"
Assert-Contains $i18n '"auth.hidePassword"' "hide-password translation"

Write-Output "Auth UX checks passed."
