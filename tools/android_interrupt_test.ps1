# Tech Empire - test d'interruptions et reprises sur le telephone (etape C1).
# A chaque cycle : lancer le jeu, toucher "Continuer", passer en arriere-plan (touche Accueil),
# verifier que la partie a ete sauvegardee et qu'elle est intacte, puis tuer l'appli comme Android.
#
#   powershell -ExecutionPolicy Bypass -File tools\android_interrupt_test.ps1 [-Cycles 20]
#
# Ne fait jamais avancer le temps du jeu (une partie chargee reprend en pause) : seule la date de sauvegarde change.
# La partie est copiee sur le PC avant le test. Le telephone ne doit pas etre utilise pendant le test.
param([int]$Cycles = 20, [int]$BootSeconds = 8)
$ErrorActionPreference = "Continue"
$Package = "com.vadorus.techempire"
$Adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $Adb)) { $Adb = (Get-ChildItem "$env:USERPROFILE\Tools" -Filter adb.exe -Recurse -Depth 4 -ErrorAction SilentlyContinue | Select-Object -First 1).FullName }
$BackupDir = Join-Path $env:USERPROFILE "Documents\TechEmpire-backups"

function Say($t) { Write-Host "[C1] $t" }
function Adb([string[]]$a) { & $Adb @a 2>&1 | Out-String }
function Read-Save {
	$raw = & $Adb exec-out run-as $Package cat files/tech_empire_save.json 2>$null | Out-String
	try { $j = $raw | ConvertFrom-Json } catch { return $null }
	if (-not $j.meta) { return $null }
	return $j.meta
}
function Same($a, $b) { $a.company -eq $b.company -and $a.month -eq $b.month -and $a.year -eq $b.year -and $a.money -eq $b.money }

& $Adb shell pidof $Package *> $null
if ($LASTEXITCODE -eq 0) { Say "ARRET : le jeu est ouvert sur le telephone."; exit 2 }
New-Item -ItemType Directory -Force $BackupDir | Out-Null
$backup = Join-Path $BackupDir ("pixel-saves-{0}-avant-test.tar" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
& cmd /c "`"$Adb`" exec-out run-as $Package tar cf - files > `"$backup`""
$base = Read-Save
if ($null -eq $base) { Say "ARRET : aucune partie lisible sur le telephone."; exit 2 }
Say ("Partie de depart : {0}, {1}/{2}, {3} EUR (copie : {4})" -f $base.company, $base.month, $base.year, $base.money, $backup)

$size = (Adb @("shell", "wm size")) -replace "[^0-9x]", ""
$dims = ($size -split "x") | ForEach-Object { [int]$_ }
$w = [math]::Max($dims[0], $dims[1]); $h = [math]::Min($dims[0], $dims[1])
$tapX = [int]($w * 0.5); $tapY = [int]($h * 0.65)   # bouton "Continuer" de l'ecran d'accueil (paysage)
$activity = ((Adb @("shell", "cmd package resolve-activity --brief $Package")) -split "`r?`n" | Where-Object { $_ -match "/" } | Select-Object -Last 1).Trim()

$failures = 0
$lastSavedAt = [int64]$base.saved_at
$starts = @()
for ($i = 1; $i -le $Cycles; $i++) {
	Adb @("shell", "am force-stop $Package") | Out-Null
	$start = Adb @("shell", "am start -W -n $activity")
	$m = [regex]::Match($start, "TotalTime:\s*(\d+)"); if ($m.Success) { $starts += [int]$m.Groups[1].Value }
	Start-Sleep -Seconds $BootSeconds
	Adb @("shell", "input tap $tapX $tapY") | Out-Null
	Start-Sleep -Seconds 4
	Adb @("shell", "input keyevent 3") | Out-Null   # Accueil : l'appli passe en arriere-plan
	Start-Sleep -Seconds 3
	$meta = Read-Save
	$tmp = (Adb @("shell", "run-as $Package ls files")) -match "\.tmp"
	$problem = ""
	if ($null -eq $meta) { $problem = "sauvegarde illisible" }
	elseif (-not (Same $meta $base)) { $problem = "partie differente : $($meta.company) $($meta.month)/$($meta.year) $($meta.money)" }
	elseif ([int64]$meta.saved_at -le $lastSavedAt) { $problem = "pas de sauvegarde au passage en arriere-plan" }
	elseif ($tmp) { $problem = "fichier temporaire laisse derriere" }
	if ($problem) { $failures++; Say ("cycle {0,2} : ECHEC - {1}" -f $i, $problem) }
	else { Say ("cycle {0,2} : ok (sauvegarde a {1})" -f $i, ([DateTimeOffset]::FromUnixTimeSeconds([int64]$meta.saved_at).LocalDateTime.ToString("HH:mm:ss"))) }
	if ($meta) { $lastSavedAt = [int64]$meta.saved_at }
	Adb @("shell", "am kill $Package") | Out-Null       # tuee en arriere-plan, comme le ferait Android
	Adb @("shell", "am force-stop $Package") | Out-Null
}
$avg = if ($starts.Count) { [int](($starts | Measure-Object -Average).Average) } else { 0 }
Say ("Bilan : {0} cycles, {1} echec(s). Demarrage Android moyen : {2} ms (+ {3} s d'attente du jeu)." -f $Cycles, $failures, $avg, $BootSeconds)
$journal = Join-Path $BackupDir "journal-installations.csv"
("{0};{1};test-interruptions;{2} cycles;{3} echec(s);demarrage {4} ms;;{5}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $env:COMPUTERNAME, $Cycles, $failures, $avg, $(if ($failures -eq 0) { "OK" } else { "ECHEC" })) | Out-File -Append -Encoding utf8 $journal
if ($failures -gt 0) { exit 1 } else { exit 0 }
