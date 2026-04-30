# Guide Pratique: Fixer le Login Facebook en 15 Minutes ⚡

## 🚀 Quick Start (Les 5 étapes essentielles)

### Étape 1: Générer le Key Hash (5 min)

**Sur Windows, ouvrir PowerShell et exécuter:**

```powershell
# Option 1 - Approche simple (recommandée)
keytool -exportcert -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android | openssl sha1 -binary | openssl base64

# Output attendu: Quelque chose comme
# rFQwGWAHw1KJzl1gJ9W6JDMxYx8=
# ⚠️ COPIER CETTE VALEUR - Vous en aurez besoin!
```

**Si vous avez une erreur `keytool` ou `openssl` n'est pas trouvé:**
- Installer [Git Bash for Windows](https://git-scm.com/download/win) (includeOpenSSL)
- OU installer [OpenSSL Windows](https://slproweb.com/products/Win32OpenSSL.html)

---

### Étape 2: Créer une App Facebook (3 min)

1. **Aller à**: https://developers.facebook.com/
2. **Login** avec votre compte Facebook
3. **Cliquer**: "My Apps" > "Create App"
4. **Choisir**: 
   - Type: **"Consumer"**
   - Nom: "MYAZZ eCommerce" (ou votre nom)
5. **Cliquer**: "Create App"
6. **Email**: Confirmer l'email si demandé
7. **Sauvegarder** l'**App ID** affiché (exemple: `1234567890123456`)

---

### Étape 3: Configurer Android dans Facebook (3 min)

1. Dans votre app Facebook, aller à: **Products** (ou "Add Product")
2. Rechercher et ajouter: **"Facebook Login"**
3. **Facebook Login** > **Settings**
4. **Add Platform** > **Android**
5. Remplir:
   ```
   Package Name: com.example.myazz
   Key Hash: [COLLER LE KEY HASH DE L'ÉTAPE 1]
   ```
6. **Cliquer Save**
7. Aller à **Settings** > **Basic** et **copier**:
   - **App ID** (16 chiffres)
   - **App Secret** (caché, cliquer "Show")

**⚠️ Ne jamais partager le App Secret!**

---

### Étape 4: Configurer Supabase (3 min)

1. **Aller à**: https://app.supabase.com/
2. **Sélectionner** votre projet
3. **Menu gauche**: Authentication > Providers
4. **Chercher "Facebook"** et **Enable**
5. **Remplir**:
   ```
   Client ID: [App ID de l'étape 3]
   Client Secret: [App Secret de l'étape 3]
   ```
6. **Save**

---

### Étape 5: Configurer les Redirect URLs (1 min)

1. **Menu**: Project Settings > API
2. **Scroll** jusqu'à "Redirect URLs"
3. **Ajouter**:
   ```
   com.example.myazz://login-callback/
   ```
4. **Save**

---

## ✅ C'est Fait! Tester Maintenant

```bash
# Terminal
flutter clean
flutter pub get
flutter run

# Dans l'app:
# - Aller à l'écran Login
# - Cliquer sur le bouton Facebook
# - Vous devriez être redirigé vers Facebook
# - Accepter les permissions
# - Revenir à l'app authentifié ✅
```

---

## 🆘 Si ça ne marche pas...

### Erreur: "Facebook login is not configured"
```
❌ Problème: Supabase ne reconnaît pas Facebook
✅ Solution: 
   1. Vérifier que Facebook Login product est activé (Étape 3)
   2. Vérifier que Client ID et Client Secret sont corrects
   3. Attendre 5-10 min (Supabase peut être en retard)
   4. Faire un flutter run
```

### Erreur: "Invalid redirect URI"
```
❌ Problème: La redirect URL ne correspond pas
✅ Solution:
   1. Vérifier que com.example.myazz://login-callback/ est ajouté en Supabase
   2. Vérifier l'orthographe exacte (case-sensitive)
   3. Vérifier les slashes: https:// ou com.example.myazz://
```

### Erreur: "Invalid Key Hash"
```
❌ Problème: Le key hash n'est pas correct
✅ Solution:
   1. Regénérer le key hash depuis le debug.keystore
   2. Copier la valeur exacte sans espaces
   3. Vérifier que c'est le SHA-1 en Base64
   4. Mettre à jour dans Facebook Developers
```

### Erreur: "App ID is invalid"
```
❌ Problème: L'App ID n'est pas correct dans Supabase
✅ Solution:
   1. Vérifier que vous avez copié l'App ID (pas App Secret)
   2. Vérifier que c'est 16 chiffres
   3. Copier à nouveau et coller dans Supabase
   4. Vérifier qu'il n'y a pas d'espaces
```

### Erreur: "keytool: command not found"
```
❌ Problème: Java n'est pas dans le PATH
✅ Solution:
   1. Installer Java Development Kit (JDK)
   2. OU utiliser le chemin complet:
      "C:\Program Files\Java\jdk-[version]\bin\keytool"
```

### Erreur: "openssl: command not found"
```
❌ Problème: OpenSSL n'est pas installé
✅ Solution:
   1. Installer Git Bash for Windows (includeOpenSSL)
   2. OU installer OpenSSL directement
   3. Utiliser Git Bash terminal au lieu de PowerShell
```

---

## 📋 Checklist Finale

Avant de déployer en production:

- [ ] App Facebook créée avec "Consumer" type
- [ ] Android Platform ajouté dans Facebook Login
- [ ] Key Hash DEBUG généré et configuré
- [ ] App ID et App Secret sauvegardés en lieu sûr
- [ ] Supabase: Facebook OAuth activé
- [ ] Supabase: Client ID et Client Secret remplis
- [ ] Supabase: Redirect URL configurée
- [ ] Test de login réussi sur l'app
- [ ] Utilisateur créé dans Supabase Auth après login

### Pour PRODUCTION (avant release):

- [ ] Créer Release Keystore
- [ ] Générer Release Key Hash
- [ ] Ajouter Release Key Hash à Facebook Developers
- [ ] Changer package name en valeur réelle (pas com.example.myazz)
- [ ] Mettre à jour toutes les URLs avec le nouveau package name
- [ ] Tester à nouveau avec le release build

---

## 💡 Tips & Tricks

### Debug des logs
```dart
// Dans auth_provider.dart, les logs vous diront exactement ce qui ne va pas:
// "Starting Facebook sign in..." → Début du processus
// "Facebook OAuth initiated successfully" → Succès!
// "Facebook AuthException: ..." → Erreur (vérifier le message)
```

### Tester plusieurs fois
- Le premier test peut être lent (OAuth a besoin de temps)
- Si ça échoue, attendre 5 sec et réessayer
- Vérifier les logs Flutter pour les erreurs exactes

### Vérifier la configuration
```bash
# Voir si Supabase reçoit les credentials
# Aller à: Supabase Dashboard > Authentication > Providers
# Facebook devrait avoir un badge vert "Enabled"
```

### Mode développeur sur Android
```bash
# Si vous testez sur device:
flutter run -d [device-id]
# Les logs s'afficheront dans le terminal
# Chercher "Facebook" pour voir les erreurs
```

---

## 🎓 Explication Rapide (Pourquoi tout ça?)

**OAuth** = "Open Authentication" - standard de sécurité pour login sans mot de passe

**Package Name** = identifiant unique de l'app sur Android (genre: `com.instagram.android`)

**Key Hash** = empreinte de votre certificat de signature - Facebook l'utilise pour vérifier que c'est vraiment VOTRE app

**App ID + Secret** = credentials de votre app Facebook - Supabase les utilise pour valider les utilisateurs

**Redirect URL** = l'adresse où Facebook renvoie après l'authentification

**DeepLink** = lien profond qui ouvre l'app depuis le navigateur (genre: `com.example.myazz://login-callback/`)

---

## 📞 Support

Si vous êtes bloqué après les 5 étapes:

1. **Vérifier les erreurs exactes** dans les logs Flutter
2. **Googler l'erreur** (99% des erreurs OAuth ont des solutions existantes)
3. **Vérifier la documentation Supabase**: https://supabase.com/docs/guides/auth/social-login/auth-facebook
4. **Vérifier la documentation Facebook**: https://developers.facebook.com/docs/facebook-login/android

---

## ⏱️ Temps Total Estimé

- Configuration initiale: **15 minutes**
- Debugging si erreur: **5-10 minutes**
- Test final: **2 minutes**
- **TOTAL: 20-30 minutes max**

Bonne chance! 🚀

