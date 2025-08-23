#!/bin/bash

# Script de deployment para Firebase Hosting
# Uso: ./deploy.sh

echo "🚀 Iniciando proceso de deployment..."

echo "📦 Limpiando proyecto..."
flutter clean

echo "🔄 Obteniendo dependencias..."
flutter pub get

echo "🧪 Ejecutando tests..."
flutter test

if [ $? -ne 0 ]; then
    echo "❌ Tests fallaron. Cancelando deployment."
    exit 1
fi

echo "🏗️ Construyendo aplicación para web..."
flutter build web --release

if [ $? -ne 0 ]; then
    echo "❌ Build falló. Cancelando deployment."
    exit 1
fi

echo "🚀 Desplegando a Firebase Hosting..."
firebase deploy --only hosting

if [ $? -eq 0 ]; then
    echo "✅ ¡Deployment exitoso!"
    echo "🌐 Tu aplicación está disponible en: https://comunity-74ad2.web.app"
else
    echo "❌ Deployment falló."
    exit 1
fi
