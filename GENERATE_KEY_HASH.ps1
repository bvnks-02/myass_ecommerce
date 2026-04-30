#!/bin/bash
# Script pour générer le Key Hash Facebook (Windows PowerShell)

# Exécuter cette commande dans PowerShell:
keytool -exportcert -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android | openssl sha1 -binary | openssl base64

# Résultat attendu: Une chaîne Base64 (ex: rFQwGWAHw1KJzl1gJ9W6JDMxYx8=)
# COPIER cette valeur - vous en aurez besoin!
