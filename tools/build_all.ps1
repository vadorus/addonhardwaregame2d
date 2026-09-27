param(
  [string]$Godot = "C:\Users\alexa\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe",
  [switch]$SkipTests,
  [switch]$Install
)
# Construit la version PC (Windows) et la version Android (APK) de Tech Empire.
# Usage : powershell -ExecutionPolicy Bypass -File tools\build_all.ps1 [-Install] [-SkipTests] [-Godot <chemin>]
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (-not (Test-Path $Godot)) { throw "Godot introuvable : $Godot (passez -Godot <chemin vers Godot_v4.7.2-stable_win64_console.exe>)" }

# Nom de l'APK et version lus dans export_presets.cfg (une seule source de vérité).
$presets = Get-Content export_presets.cfg -Encoding UTF8
$apkPath = ($presets | Where-Object { $_ -match '^export_path="build/android/' } | Select-Object -First 1) -replace '^export_path="(.*)"$', '$1'
$versionName = ($presets | Where-Object { $_ -match '^version/name=' } | Select-Object -First 1) -replace '^version/name="(.*)"$', '$1'
if (-not $apkPath) { $apkPath = "build/android/TechEmpire-debug.apk" }
Write-Host "Tech Empire $versionName — build PC + Android" -ForegroundColor Cyan

New-Item -ItemType Directory build/windows, build/android -Force | Out-Null
if (-not (Test-Path build/.gdignore)) { New-Item -ItemType File build/.gdignore | Out-Null }

Write-Host "1/4 Import du projet"
& $Godot --headless --path . --import 2>&1 | Out-Null

if (-not $SkipTests) {
  Write-Host "2/4 Tests"
  foreach ($scene in @("tests/smoke_test.tscn", "tests/garage_layout_test.tscn", "tests/workshop_layout_test.tscn")) {
    $log = & $Godot --headless --path . "res://$scene" 2>&1 | Out-String
    if ($log -match 'SCRIPT ERROR|Parse Error' -or $log -notmatch '\[CI\].*passed') {
      Write-Host $log
      throw "Test en échec : $scene — build annulé."
    }
    Write-Host "   OK $scene"
  }
} else {
  Write-Host "2/4 Tests sautés (-SkipTests)" -ForegroundColor Yellow
}

Write-Host "3/4 Export Windows"
& $Godot --headless --path . --export-release "Windows Desktop" build/windows/TechEmpire.exe 2>&1 | Out-Null
if (-not (Test-Path build/windows/TechEmpire.exe)) { throw "L'export Windows a échoué (modèles d'export 4.7.2 installés ?)" }

Write-Host "4/4 Export Android"
& $Godot --headless --path . --export-debug "Android APK" $apkPath 2>&1 | Out-Null
if (-not (Test-Path $apkPath)) { throw "L'export Android a échoué (JDK 17, Android SDK et clé de debug configurés dans l'éditeur ?)" }

Get-Item build/windows/TechEmpire.exe, $apkPath | ForEach-Object { "{0,8:N1} Mo  {1}" -f ($_.Length / 1MB), $_.FullName }

if ($Install) {
  $adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
  if (-not (Test-Path $adb)) { throw "adb introuvable : $adb" }
  Write-Host "Installation sur le téléphone (mise à jour, parties conservées)"
  & $adb install -r $apkPath
}
Write-Host "Terminé." -ForegroundColor Green
