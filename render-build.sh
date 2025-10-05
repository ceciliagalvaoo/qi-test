#!/bin/bash

# Instalar Flutter
echo "🔧 Instalando Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$PWD/flutter/bin"

# Aceitar licenças
flutter --version
flutter doctor

# Build do Flutter Web
echo "🔨 Construindo Flutter Web..."
cd simple_split_frontend
flutter pub get
flutter build web --dart-define=API_URL=/api

# Mover build do Flutter para pasta static do Flask  
echo "📁 Movendo arquivos do Flutter..."
mkdir -p ../simple_split_backend/static
cp -r build/web/* ../simple_split_backend/static/

# Instalar dependências Python
echo "📦 Instalando dependências Python..."
cd ../simple_split_backend
pip install -r requirements.txt

echo "✅ Build completo - Frontend + Backend!"