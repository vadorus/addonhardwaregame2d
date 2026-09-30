param(
  [string]$Godot = "",
  [switch]$SkipTests,
  [switch]$Install
)
# Construit la version PC (Windows) et la version Android (APK) de Tech Empire.
# Usage : powershell -ExecutionPolicy Bypass -File tools\build_all.ps1 [-Install] [-SkipTests] [-Godot <chemin>]
# V0.10 / Q0 : l'APK est toujours signé avec la clé de test commune du projet
# (tools/android/techempire-debug.keystore), quel que soit le PC. Une mise à jour ne demande donc
# jamais de désinstaller le jeu, et les parties du téléphone sont conservées.
# « Continue » : Godot écrit parfois des avertissements sur la sortie d'erreur ; ils ne doivent pas
# interrompre le build. Les vrais échecs sont détectés explicitement plus bas (throw).
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# Empreinte attendue du certificat de test commun (SHA-256).
$ExpectedCert = "997747a416da98eb1f09f371a922365203a71addea7ee8544b4102e74f49a4bb"
$Keystore = Join-Path $root "tools\android\techempire-debug.keystore"

function Find-First([string[]]$candidates) {
  foreach ($c in $candidates) { if ($c -and (Test-Path $c)) { return $c } }
  return $null
}
function Read-EditorSetting([string]$key) {
  $file = Get-ChildItem "$env:APPDATA\Godot" -Filter "editor_settings-4.*.tres" -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
  if (-not $file) { return $null }
  $line = Select-String -Path $file.FullName -Pattern ("^" + [regex]::Escape($key) + ' = "(.*)"') | Select-Object -First 1
  if ($line) { return $line.Matches[0].Groups[1].Value -replace '/', '\' }
  return $null
}

# Godot : paramètre, variable GODOT, ou emplacements connus des deux PC.
$Godot = Find-First @($Godot, $env:GODOT,
  "C:\Users\alexa\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe",
  "C:\Users\Admin\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe",
  "C:\Users\Admin\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe")
if (-not $Godot) { throw "Godot 4.7.2 introuvable : passez -Godot <chemin vers Godot_v4.7.2-stable_win64_console.exe> ou définissez GODOT." }
if (-not (Test-Path $Keystore)) { throw "Clé de test commune absente : $Keystore" }

# Signature : Godot lit ces variables à l'export (prioritaires sur les réglages de l'éditeur).
$env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH = $Keystore
$env:GODOT_ANDROID_KEYSTORE_DEBUG_USER = "androiddebugkey"
$env:GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD = "android"

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
  foreach ($scene in @("tests/smoke_test.tscn", "tests/garage_layout_test.tscn", "tests/workshop_layout_test.tscn", "tests/balance_ceiling_test.tscn")) {
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
$winTemplate = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable\windows_release_x86_64.exe"
if (Test-Path $winTemplate) {
  & $Godot --headless --path . --export-release "Windows Desktop" build/windows/TechEmpire.exe 2>&1 | Out-Null
  if (-not (Test-Path build/windows/TechEmpire.exe)) { throw "L'export Windows a échoué (modèles d'export 4.7.2 installés ?)" }
} else {
  # Le PC du travail n'a que les modèles Android : on saute la version PC au lieu d'échouer.
  Write-Host "   Modèle d'export Windows absent sur ce PC : version PC sautée." -ForegroundColor Yellow
}

Write-Host "4/4 Export Android"
if (Test-Path $apkPath) { Remove-Item $apkPath -Force }
& $Godot --headless --path . --export-debug "Android APK" $apkPath 2>&1 | Out-Null
if (-not (Test-Path $apkPath)) { throw "L'export Android a échoué (JDK 17 et Android SDK configurés dans l'éditeur ?)" }

# Vérifie que l'APK porte bien la clé commune (sinon, l'installation effacerait les parties).
$sdk = Find-First @((Read-EditorSetting "export/android/android_sdk_path"), (Join-Path $env:LOCALAPPDATA "Android\Sdk"), "C:\Users\Admin\Tools\Android\Sdk")
$java = Read-EditorSetting "export/android/java_sdk_path"
if ($java) { $env:JAVA_HOME = $java }
$apksigner = if ($sdk) { Get-ChildItem (Join-Path $sdk "build-tools") -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | ForEach-Object { Join-Path $_.FullName "apksigner.bat" } | Where-Object { Test-Path $_ } | Select-Object -First 1 } else { $null }
if ($apksigner) {
  $certs = & $apksigner verify --print-certs $apkPath 2>&1 | Out-String
  if ($certs -notmatch $ExpectedCert) { throw "L'APK n'est pas signé avec la clé de test commune — installation annulée pour protéger les parties." }
  Write-Host "   Signature : clé de test commune OK"
} else {
  Write-Host "   (apksigner introuvable : signature non vérifiée)" -ForegroundColor Yellow
}

@("build/windows/TechEmpire.exe", $apkPath) | Where-Object { Test-Path $_ } | ForEach-Object { Get-Item $_ } | ForEach-Object { "{0,8:N1} Mo  {1}" -f ($_.Length / 1MB), $_.FullName }

if ($Install) {
  $adb = if ($sdk) { Join-Path $sdk "platform-tools\adb.exe" } else { $null }
  if (-not $adb -or -not (Test-Path $adb)) { throw "adb introuvable (Android SDK non trouvé)" }
  # Copie de sécurité de la partie du téléphone avant toute installation.
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $backup = Join-Path $root "build\pixel_saves\$stamp"
  New-Item -ItemType Directory $backup -Force | Out-Null
  foreach ($f in @("tech_empire_save.json", "tech_empire_save.json.bak", "tech_empire_slot_1.json", "tech_empire_slot_2.json", "tech_empire_slot_3.json")) {
    cmd /c "`"$adb`" exec-out run-as com.vadorus.techempire cat files/$f > `"$backup\$f`" 2>nul"
    # Emplacement vide : run-as renvoie un message d'erreur au lieu d'un JSON. On ne garde que les vraies parties.
    if ((Test-Path "$backup\$f") -and -not ((Get-Content "$backup\$f" -TotalCount 1 -Encoding UTF8) -match '^\s*\{')) { Remove-Item "$backup\$f" }
  }
  Write-Host "   Parties du téléphone copiées dans $backup"
  Write-Host "Installation sur le téléphone (mise à jour, parties conservées)"
  $result = & $adb install -r $apkPath 2>&1 | Out-String
  Write-Host $result
  if ($result -match "INSTALL_FAILED_UPDATE_INCOMPATIBLE") {
    throw "Le jeu du téléphone a été signé avec une autre clé. Ne pas désinstaller sans copier les parties : voir docs/BUILD_PC_ANDROID.md, section « Clé de signature commune »."
  }
}
Write-Host "Terminé." -ForegroundColor Green
