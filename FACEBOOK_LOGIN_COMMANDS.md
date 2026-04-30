# 🚀 Commandes Prêtes à Copier-Coller pour Facebook Login

## 📋 Chaque commande est sur une ligne - Copier et Coller dans PowerShell

---

## ÉTAPE 1️⃣: Générer le Key Hash

### Méthode 1 - PowerShell (Recommandé)
```powershell
keytool -exportcert -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android | openssl sha1 -binary | openssl base64
```

**Résultat attendu**: Une chaîne Base64 comme `rFQwGWAHw1KJzl1gJ9W6JDMxYx8=`

📌 **COPIER CETTE VALEUR** - Vous en aurez besoin pour Facebook!

---

### Méthode 2 - Si Méthode 1 ne marche pas (Git Bash)
1. **Installer**: https://git-scm.com/download/win
2. **Ouvrir Git Bash** (au lieu de PowerShell)
3. **Exécuter**:
```bash
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android | openssl sha1 -binary | openssl base64
```

---

### Méthode 3 - Voir tous les certificats disponibles (pour debug)
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android
```

---

## ÉTAPE 2️⃣: Nettoyer et Rebuild l'App Flutter

```powershell
cd d:\developement\myass_ecommerce
flutter clean
flutter pub get
```

---

## ÉTAPE 3️⃣: Lancer l'App pour Tester

```powershell
flutter run
```

Pour tester sur émulateur spécifique:
```powershell
flutter run -d emulator  # Liste les devices d'abord avec: flutter devices
```

---

## ÉTAPE 4️⃣: Voir les Logs en Temps Réel

```powershell
flutter logs
```

**À chercher dans les logs**:
```
Starting Facebook sign in...
Facebook OAuth initiated successfully    ✅ = Succès!
Facebook AuthException:                  ❌ = Erreur (vérifier le message)
```

---

## ÉTAPE 5️⃣: Si Erreur - Voir les Détails

```powershell
flutter logs -f | findstr "Facebook"   # Affiche que les lignes avec "Facebook"
```

---

## 🔄 Script Complet - Tout d'un coup

### Copier-Coller Complet (Exécuter dans PowerShell):

```powershell
# ==========================================
# 1. Afficher le Key Hash (copier la valeur!)
# ==========================================
Write-Host "=== ÉTAPE 1: Générer Key Hash ===" -ForegroundColor Green
keytool -exportcert -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android | openssl sha1 -binary | openssl base64
Write-Host ""
Write-Host "⚠️  COPIER LA VALEUR CI-DESSUS - Vous en aurez besoin!" -ForegroundColor Yellow
Write-Host ""

# Pause - L'utilisateur peut copier
Read-Host "✅ Appuyer sur ENTRÉE une fois que vous avez copié le Key Hash"

# ==========================================
# 2. Nettoyer et rebuild
# ==========================================
Write-Host ""
Write-Host "=== ÉTAPE 2: Nettoyer et Rebuild ===" -ForegroundColor Green
cd d:\developement\myass_ecommerce
flutter clean
flutter pub get

# ==========================================
# 3. Lancer l'app
# ==========================================
Write-Host ""
Write-Host "=== ÉTAPE 3: Lancer l'App ===" -ForegroundColor Green
Write-Host "L'app va démarrer... Attendez quelques secondes"
flutter run

# ==========================================
# 4. Logs
# ==========================================
Write-Host ""
Write-Host "=== Logs en Temps Réel ===" -ForegroundColor Green
Write-Host "Chercher 'Starting Facebook sign in' et 'Facebook OAuth initiated successfully'"
flutter logs
```

---

## 📝 Notes Importantes

- ❌ **Ne pas oublier** le Key Hash généré - C'est la clé!
- ❌ **Ne pas utiliser** `com.example.myazz` en production (utiliser votre vrai package name)
- ❌ **Ne jamais partager** l'App Secret Facebook avec quelqu'un d'autre
- ✅ **Mettre à jour** Supabase immédiatement après avoir configuré Facebook
- ✅ **Vérifier** que la Redirect URL est exacte (avec les slashes corrects)

---

## 🔐 Pour Production - Après Tests

### Générer Release Key Hash (une seule fois)

```powershell
# D'abord, créer le release.keystore
keytool -genkey -v -keystore "$env:USERPROFILE\.android\release.keystore" -keyalg RSA -keysize 2048 -validity 10000 -alias production

# Ensuite, générer le key hash du release
keytool -exportcert -alias production -keystore "$env:USERPROFILE\.android\release.keystore" | openssl sha1 -binary | openssl base64
```

---

## 🆘 Troubleshooting - Commandes Utiles

### Si "keytool not found"
```powershell
# Chercher keytool
Get-Command keytool

# Si rien, chercher Java:
Get-Command java

# Si rien, installer: https://www.oracle.com/java/technologies/downloads/
```

### Si "openssl not found"
```powershell
# Installer Git Bash et utiliser celui-ci
# OU installer: https://slproweb.com/products/Win32OpenSSL.html
```

### Vérifier que Android Debug Keystore existe
```powershell
Test-Path "$env:USERPROFILE\.android\debug.keystore"
# Résultat: True = OK, False = Problème
```

### Voir la liste des appareils connectés
```powershell
flutter devices
```

### Lancer sur un device spécifique
```powershell
flutter run -d [device-id]
```

### Hot Reload (sans rebuild complet)
```
Taper 'r' dans le terminal Flutter
```

### Hot Restart (rebuild complet)
```
Taper 'R' dans le terminal Flutter (majuscule)
```

---

## 📊 Checklist d'Exécution

- [ ] Généré et copié le Key Hash
- [ ] Créé l'app Facebook avec Consumer type
- [ ] Configuré Android Platform dans Facebook Login
- [ ] Collé le Key Hash dans Facebook Developers
- [ ] Copié App ID et App Secret
- [ ] Configuré Facebook OAuth dans Supabase
- [ ] Collé App ID et App Secret dans Supabase
- [ ] Configuré Redirect URL dans Supabase
- [ ] Exécuté `flutter clean && flutter pub get`
- [ ] Lancé `flutter run`
- [ ] Testé le bouton Facebook Login
- [ ] Vérifié les logs pour erreurs

---

## 💬 Messages d'Erreur Courants et Solutions

| Message | Cause | Commande pour Déboguer |
|---------|-------|----------------------|
| `keytool: command not found` | Java non installé | `Get-Command java` |
| `openssl: command not found` | OpenSSL non installé | Installer Git Bash |
| `Facebook login is not configured` | Supabase n'est pas activé | Vérifier Supabase Dashboard |
| `Invalid redirect URI` | URL ne correspond pas | Vérifier exactement dans Supabase |
| `Invalid Key Hash` | Hash incorrect | Regénérer avec la commande ci-dessus |

---

## 🎯 Ordre d'Exécution Recommandé

1. **Exécuter**: Générer Key Hash (Étape 1)
2. **Aller à**: Facebook Developers et configurer (5 min)
3. **Aller à**: Supabase et configurer (5 min)
4. **Attendre**: 2-5 min (Supabase met à jour)
5. **Exécuter**: flutter clean && flutter pub get
6. **Exécuter**: flutter run
7. **Tester**: Cliquer sur Facebook Login dans l'app

---

Bonne chance! 🚀 Si vous avez des erreurs, les commandes de logs ci-dessus vous aideront à les identifier!

