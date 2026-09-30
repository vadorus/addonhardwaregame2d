# Règle l'éditeur Godot de CE PC pour signer les APK de test avec la clé commune du projet.
# À lancer une fois par PC (Godot fermé) : powershell -ExecutionPolicy Bypass -File tools\setup_debug_keystore.ps1
# Ainsi, même un export fait depuis l'éditeur ou en ligne de commande sans build_all.ps1 garde la même signature,
# et une mise à jour du jeu sur le téléphone ne demande jamais de désinstaller (donc n'efface jamais les parties).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$keystore = (Join-Path $root "tools\android\techempire-debug.keystore") -replace '\\', '/'
if (-not (Test-Path $keystore)) { throw "Clé commune absente : $keystore" }
if (Get-Process -Name "Godot*" -ErrorAction SilentlyContinue) { Write-Host "Attention : fermez Godot avant (il réécrit ses réglages en quittant)." -ForegroundColor Yellow }
$files = Get-ChildItem "$env:APPDATA\Godot" -Filter "editor_settings-4.*.tres" -ErrorAction SilentlyContinue
if (-not $files) { throw "Aucun réglage d'éditeur Godot 4 trouvé sur ce PC (ouvrez Godot une fois)." }
$wanted = [ordered]@{
  "export/android/debug_keystore" = $keystore
  "export/android/debug_keystore_user" = "androiddebugkey"
  "export/android/debug_keystore_pass" = "android"
}
foreach ($file in $files) {
  Copy-Item $file.FullName ($file.FullName + ".avant_cle_commune") -Force
  $lines = [System.Collections.Generic.List[string]](Get-Content $file.FullName -Encoding UTF8)
  foreach ($key in $wanted.Keys) {
    $newLine = '{0} = "{1}"' -f $key, $wanted[$key]
    $index = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match ('^' + [regex]::Escape($key) + ' = ')) { $index = $i; break } }
    if ($index -ge 0) { $lines[$index] = $newLine }
    else {
      $anchor = -1
      for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^export/android/') { $anchor = $i } }
      if ($anchor -ge 0) { $lines.Insert($anchor + 1, $newLine) } else { $lines.Add($newLine) }
    }
  }
  [IO.File]::WriteAllLines($file.FullName, $lines, (New-Object Text.UTF8Encoding $false))
  Write-Host "Réglé : $($file.Name) -> $keystore"
}
Write-Host "Terminé. Copie de l'ancien réglage : *.avant_cle_commune" -ForegroundColor Green
