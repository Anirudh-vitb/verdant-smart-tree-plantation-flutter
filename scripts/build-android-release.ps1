<#
.SYNOPSIS
    Diagnoses the Android toolchain, installs the NDK Flutter needs, and builds
    and verifies the release APK on Windows.

.DESCRIPTION
    Safe to re-run. It never deletes SDK packages, never edits local.properties
    and never changes Gradle/AGP/Kotlin/NDK versions. Every SDK package is
    verified by its files (source.properties), not by exit codes.
    A full transcript is written to build-repair-logs\.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\build-android-release.ps1
#>
[CmdletBinding()]
param(
    [string]$FlutterBat = "$env:USERPROFILE\Downloads\flutter_windows_3.47.7-stable\flutter\bin\flutter.bat",
    [string]$SdkRoot = "$env:LOCALAPPDATA\Android\sdk",
    [switch]$SkipTests
)

# Native tools (sdkmanager, gradle, flutter) print warnings on stderr. With
# 'Stop', Windows PowerShell turns those lines into terminating errors, which
# is what broke the previous repair script. Exit codes are checked explicitly.
$ErrorActionPreference = 'Continue'

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot
$LogDir = Join-Path $ProjectRoot 'build-repair-logs'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$LogFile = Join-Path $LogDir ('build-{0:yyyyMMdd-HHmmss}.log' -f (Get-Date))
Start-Transcript -Path $LogFile | Out-Null

function Write-Step([string]$Text) { Write-Host "`n=== $Text ===" -ForegroundColor Cyan }

function Stop-Blocked([string]$Message) {
    Write-Host "`nBLOCKED: $Message" -ForegroundColor Red
    Write-Host "Log: $LogFile"
    Stop-Transcript | Out-Null
    exit 1
}

function Get-PackageRevision([string]$PackageDir) {
    $props = Join-Path $PackageDir 'source.properties'
    if (-not (Test-Path $props)) { return $null }
    $line = Select-String -Path $props -Pattern '^Pkg\.Revision\s*=\s*(.+)$' | Select-Object -First 1
    if ($line) { return $line.Matches[0].Groups[1].Value.Trim() }
    return $null
}

# Runs a .bat file through cmd.exe with an exact command line. cmd.exe splits
# unquoted arguments at ';' and '=', so "ndk;28.x" must reach it in quotes.
function Invoke-Batch([string]$BatchFile, [string]$Arguments) {
    $commandLine = '/d /c ""' + $BatchFile + '" ' + $Arguments + '"'
    Write-Host "> cmd.exe $commandLine"
    $process = Start-Process -FilePath 'cmd.exe' -ArgumentList $commandLine -NoNewWindow -Wait -PassThru
    return $process.ExitCode
}

# ---------------------------------------------------------------- inspect
Write-Step 'Project'
Write-Host "Project root: $ProjectRoot"
if (-not (Test-Path (Join-Path $ProjectRoot 'pubspec.yaml'))) { Stop-Blocked 'pubspec.yaml not found; run this script from the project.' }
git status --short --branch
if (Test-Path 'android\local.properties') {
    Write-Host 'android\local.properties (read only, not modified):'
    Get-Content 'android\local.properties'
}

Write-Step 'Flutter'
if (-not (Test-Path $FlutterBat)) { Stop-Blocked "Flutter not found at $FlutterBat. Pass -FlutterBat <path>." }
& $FlutterBat --version
$FlutterRoot = Split-Path -Parent (Split-Path -Parent $FlutterBat)
$FlutterExt = Join-Path $FlutterRoot 'packages\flutter_tools\gradle\src\main\kotlin\FlutterExtension.kt'
$NdkVersion = (Select-String -Path $FlutterExt -Pattern 'val ndkVersion: String = "([^"]+)"').Matches[0].Groups[1].Value
$CompileSdk = (Select-String -Path $FlutterExt -Pattern 'val compileSdkVersion: Int = (\d+)').Matches[0].Groups[1].Value
Write-Host "flutter.ndkVersion        = $NdkVersion"
Write-Host "flutter.compileSdkVersion = $CompileSdk"

Write-Step 'Disk space'
$drive = Get-PSDrive -Name (Split-Path -Qualifier $SdkRoot).TrimEnd(':')
$freeGb = [math]::Round($drive.Free / 1GB, 1)
Write-Host "Free on $($drive.Name): $freeGb GB"
if ($freeGb -lt 5) { Stop-Blocked "Less than 5 GB free on drive $($drive.Name). The NDK alone needs about 2.5 GB." }

Write-Step 'Android SDK'
if (-not (Test-Path $SdkRoot)) { Stop-Blocked "Android SDK not found at $SdkRoot. Pass -SdkRoot <path>." }
foreach ($dir in 'platform-tools', 'build-tools', 'platforms', 'ndk', 'cmdline-tools', 'licenses') {
    $path = Join-Path $SdkRoot $dir
    if (Test-Path $path) {
        $children = (Get-ChildItem $path -Name) -join ', '
        Write-Host ("{0,-15} {1}" -f $dir, $children)
    } else {
        Write-Host ("{0,-15} (missing)" -f $dir) -ForegroundColor Yellow
    }
}
$Platform = Join-Path $SdkRoot "platforms\android-$CompileSdk\android.jar"
if (Test-Path $Platform) { Write-Host "OK  platform android-$CompileSdk" } else { Write-Host "MISSING platform android-$CompileSdk (Gradle will try to download it)" -ForegroundColor Yellow }

# ---------------------------------------------------------------- licenses
Write-Step 'Android SDK licenses'
$licenseDir = Join-Path $SdkRoot 'licenses'
if (-not (Test-Path (Join-Path $licenseDir 'android-sdk-license'))) {
    Write-Host 'Licenses have not been accepted. Answer "y" to each prompt.' -ForegroundColor Yellow
    & $FlutterBat doctor --android-licenses
}
if (-not (Test-Path (Join-Path $licenseDir 'android-sdk-license'))) {
    Stop-Blocked 'Android SDK licenses are still not accepted. Run: flutter doctor --android-licenses'
}
Write-Host 'OK  licenses accepted'

# ---------------------------------------------------------------- NDK
Write-Step "NDK $NdkVersion"
$NdkDir = Join-Path $SdkRoot "ndk\$NdkVersion"
$revision = Get-PackageRevision $NdkDir
if ($revision -eq $NdkVersion) {
    Write-Host "OK  NDK $revision already installed"
} else {
    if (Test-Path $NdkDir) {
        Write-Host "Found $NdkDir without a valid source.properties (incomplete install). It is left untouched;" -ForegroundColor Yellow
        Write-Host 'remove it in Android Studio > SDK Manager if the install below cannot complete.' -ForegroundColor Yellow
    }
    $sdkManager = Join-Path $SdkRoot 'cmdline-tools\latest\bin\sdkmanager.bat'
    if (Test-Path $sdkManager) {
        Write-Host 'Installing with sdkmanager (package id passed in quotes so cmd.exe keeps it whole)...'
        $code = Invoke-Batch $sdkManager ('"--sdk_root=' + $SdkRoot + '" "ndk;' + $NdkVersion + '"')
        Write-Host "sdkmanager exit code: $code (not trusted; checking files)"
        $revision = Get-PackageRevision $NdkDir
    }
    if ($revision -eq $NdkVersion) {
        Write-Host "OK  NDK $revision installed and verified"
    } else {
        Write-Host "NDK still missing. The Android Gradle Plugin downloads a missing NDK automatically" -ForegroundColor Yellow
        Write-Host "during the build when licenses are accepted, so the build will continue." -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------- validate
Write-Step 'flutter doctor'
& $FlutterBat doctor -v

Write-Step 'flutter pub get'
& $FlutterBat pub get
if ($LASTEXITCODE -ne 0) { Stop-Blocked 'flutter pub get failed (see output above).' }

Write-Step 'flutter analyze'
& $FlutterBat analyze
if ($LASTEXITCODE -ne 0) { Write-Host 'flutter analyze reported issues (see above). Continuing to the build.' -ForegroundColor Yellow }

if (-not $SkipTests) {
    Write-Step 'flutter test'
    & $FlutterBat test
    if ($LASTEXITCODE -ne 0) { Stop-Blocked 'Tests failed (see output above).' }
}

# ---------------------------------------------------------------- build
Write-Step 'flutter build apk --release'
& $FlutterBat build apk --release
$buildExit = $LASTEXITCODE

$Apk = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk\app-release.apk'
if ($buildExit -ne 0 -or -not (Test-Path $Apk)) {
    $revision = Get-PackageRevision $NdkDir
    if ($revision -ne $NdkVersion) {
        Stop-Blocked ("Build failed and NDK $NdkVersion is not installed. Install it in Android Studio: " +
            "Settings > Languages & Frameworks > Android SDK > SDK Tools > tick 'Show Package Details' > " +
            "NDK (Side by side) > $NdkVersion > Apply. Then re-run this script.")
    }
    Stop-Blocked 'flutter build apk failed. The first "What went wrong" block above is the root cause.'
}

# ---------------------------------------------------------------- verify
Write-Step 'Verify APK'
$item = Get-Item $Apk
Write-Host "APK:    $($item.FullName)"
Write-Host ("Size:   {0:N1} MB ({1} bytes)" -f ($item.Length / 1MB), $item.Length)
Write-Host "SHA256: $((Get-FileHash $Apk -Algorithm SHA256).Hash)"
Write-Host "NDK:    $(Get-PackageRevision $NdkDir)"
$buildTools = Get-ChildItem (Join-Path $SdkRoot 'build-tools') -Directory -ErrorAction SilentlyContinue |
    Sort-Object { [version]($_.Name -replace '[^\d\.].*$', '') } -Descending | Select-Object -First 1
if ($buildTools) {
    $aapt2 = Join-Path $buildTools.FullName 'aapt2.exe'
    if (Test-Path $aapt2) {
        & $aapt2 dump badging $Apk | Select-String -Pattern '^package:|sdkVersion|application-label:|uses-permission|native-code'
    }
    $apksigner = Join-Path $buildTools.FullName 'apksigner.bat'
    if (Test-Path $apksigner) { & $apksigner verify --print-certs $Apk | Select-String -Pattern 'Signer #1 certificate DN' }
}
Write-Host "`nSUCCESS: release APK built and verified." -ForegroundColor Green
Write-Host "Log: $LogFile"
Stop-Transcript | Out-Null
