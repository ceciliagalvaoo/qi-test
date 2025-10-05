# Build do Flutter Web
echo "🔨 Construindo Flutter Web..."
cd simple_split_frontend
flutter build web --dart-define=API_URL=/api

# Mover build do Flutter para pasta static do Flask  
echo "📁 Movendo arquivos do Flutter..."
mkdir -p ../simple_split_backend/static
cp -r build/web/* ../simple_split_backend/static/

# Instalar dependências Python
echo "📦 Instalando dependências Python..."
cd ../simple_split_backend
pip install -r requirements.txt

echo "✅ Build completo!"