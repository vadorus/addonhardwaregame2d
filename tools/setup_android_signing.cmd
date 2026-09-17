@echo off
setlocal
set "GH=%USERPROFILE%\.local\gh\bin\gh.exe"
set "KEYTOOL=C:\Program Files\Eclipse Adoptium\jdk-17.0.10.7-hotspot\bin\keytool.exe"
set "SIGNDIR=%USERPROFILE%\.techempire\signing"
set "KEYSTORE=%SIGNDIR%\techempire-release.jks"
set "REPO=vadorus/addonhardwaregame2d"

if not exist "%SIGNDIR%" mkdir "%SIGNDIR%"
if not exist "%GH%" echo GitHub CLI introuvable.& pause & exit /b 1
if not exist "%KEYTOOL%" echo keytool introuvable.& pause & exit /b 1

"%GH%" auth status --hostname github.com >nul 2>&1
if errorlevel 1 "%GH%" auth login --hostname github.com --git-protocol https --web
if errorlevel 1 echo Connexion GitHub echouee.& pause & exit /b 1

if not exist "%KEYSTORE%" "%KEYTOOL%" -genkeypair -keystore "%KEYSTORE%" -alias techempire -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Tech Empire,O=Tech Empire,C=FR"
if errorlevel 1 echo Creation de la cle echouee.& pause & exit /b 1

echo Envoi securise de la cle vers GitHub Actions...
powershell -NoProfile -Command "[Convert]::ToBase64String([IO.File]::ReadAllBytes('%KEYSTORE%'))" | "%GH%" secret set TECH_EMPIRE_ANDROID_KEYSTORE_B64 --repo "%REPO%"
if errorlevel 1 echo Envoi de la cle echoue.& pause & exit /b 1

"%GH%" secret set TECH_EMPIRE_ANDROID_KEY_ALIAS --repo "%REPO%" --body techempire
if errorlevel 1 echo Envoi de l alias echoue.& pause & exit /b 1

echo.
echo Saisis maintenant LE MEME mot de passe de signature quand GitHub CLI le demande.
"%GH%" secret set TECH_EMPIRE_ANDROID_KEY_PASSWORD --repo "%REPO%"
if errorlevel 1 echo Envoi du mot de passe echoue.& pause & exit /b 1

echo.
echo Signature Android permanente configuree.
echo Garde le fichier %KEYSTORE% dans un emplacement sauvegarde et prive.
pause
