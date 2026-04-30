# Script PowerShell pour générer le Key Hash Facebook - SANS OpenSSL!
# Exécuter ce script dans PowerShell

$keystore = "$env:USERPROFILE\.android\debug.keystore"

# Vérifier que le keystore existe
if (-Not (Test-Path $keystore)) {
    Write-Host "ERREUR: debug.keystore non trouve a: $keystore" -ForegroundColor Red
    exit 1
}

Write-Host "Keystore trouve: $keystore" -ForegroundColor Green

# Exporter le certificat dans un fichier temporaire
$tempCert = [System.IO.Path]::GetTempFileName()
Write-Host "⏳ Exportation du certificat..." -ForegroundColor Yellow

& keytool -exportcert -alias androiddebugkey -keystore $keystore -storepass android -file $tempCert

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERREUR: keytool a échoué" -ForegroundColor Red
    exit 1
}

# Lire les bytes du certificat
$certBytes = [System.IO.File]::ReadAllBytes($tempCert)

# Calculer SHA1
Write-Host "⏳ Calcul du SHA1..." -ForegroundColor Yellow
$sha1 = [System.Security.Cryptography.SHA1]::Create().ComputeHash($certBytes)

# Encoder en Base64
Write-Host "⏳ Encodage en Base64..." -ForegroundColor Yellow
$base64 = [Convert]::ToBase64String($sha1)

# Nettoyer le fichier temporaire
Remove-Item $tempCert -Force

# Afficher le résultat
Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "KEY HASH GENERE AVEC SUCCES!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "KEY HASH (Facebook Login):" -ForegroundColor Cyan
Write-Host $base64 -ForegroundColor Yellow -BackgroundColor Black
Write-Host ""
Write-Host "COPIER CETTE VALEUR POUR FACEBOOK DEVELOPERS!" -ForegroundColor Green
Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
