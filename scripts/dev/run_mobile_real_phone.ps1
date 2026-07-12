param(
    [string]$BackendUrl = "http://127.0.0.1:8080"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$mobileDir = Join-Path $repoRoot "apps\mobile"

function Resolve-AdbPath {
    $pathAdb = Get-Command adb -ErrorAction SilentlyContinue
    if ($pathAdb) {
        return $pathAdb.Source
    }

    $candidateRoots = @(
        $env:ANDROID_HOME,
        $env:ANDROID_SDK_ROOT,
        (Join-Path $env:LOCALAPPDATA "Android\Sdk"),
        (Join-Path $env:USERPROFILE "AppData\Local\Android\Sdk")
    ) | Where-Object { $_ -and $_.Trim().Length -gt 0 } | Select-Object -Unique

    foreach ($root in $candidateRoots) {
        $candidate = Join-Path $root "platform-tools\adb.exe"
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    throw "adb.exe was not found. Install Android SDK Platform Tools or add platform-tools to PATH."
}

$adbPath = Resolve-AdbPath

Write-Host "SmartKash mobile dev run" -ForegroundColor Cyan
Write-Host "Backend URL: $BackendUrl"
Write-Host "ADB: $adbPath"

try {
    $health = Invoke-WebRequest -UseBasicParsing "http://localhost:8080/actuator/health" -TimeoutSec 5
    Write-Host "Backend health check: $($health.Content)" -ForegroundColor Green
} catch {
    Write-Host "Backend is not reachable at http://localhost:8080/actuator/health" -ForegroundColor Yellow
    Write-Host "Start backend first: cd services/backend; .\mvnw.cmd spring-boot:run" -ForegroundColor Yellow
}

Write-Host "Checking connected Android devices..."
& $adbPath devices

Write-Host "Mapping Android device/emulator port 8080 to PC localhost:8080..."
& $adbPath reverse tcp:8080 tcp:8080
& $adbPath reverse --list

Write-Host "Running Flutter app with stable adb-reverse backend URL..."
Push-Location $mobileDir
try {
    flutter run --dart-define "SMARTKASH_API_BASE_URL=$BackendUrl"
} finally {
    Pop-Location
}
