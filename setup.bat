@echo off
echo =========================================
echo    THE SIMPLE SPLIT - MVP Setup
echo =========================================
echo.

echo [1/4] Verificando Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python nao encontrado. Por favor, instale Python 3.8 ou superior.
    echo    Download: https://www.python.org/downloads/
    pause
    exit /b 1
) else (
    echo ✅ Python encontrado
)

echo.
echo [2/4] Configurando Backend...
cd simple_split_backend

echo    ⏳ Instalando dependencias Python...
pip install -r requirements.txt >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Erro ao instalar dependencias Python
    pause
    exit /b 1
) else (
    echo ✅ Dependencias Python instaladas
)

echo    ⏳ Inicializando banco de dados...
python test_backend.py >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Erro ao inicializar banco de dados
    pause
    exit /b 1
) else (
    echo ✅ Banco de dados inicializado com usuarios de teste
)

echo.
echo [3/4] Verificando Flutter...
cd ..\simple_split_frontend
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter nao encontrado. Por favor, instale Flutter SDK.
    echo    Download: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
) else (
    echo ✅ Flutter encontrado
)

echo    ⏳ Instalando dependencias Flutter...
flutter pub get >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Erro ao instalar dependencias Flutter
    pause
    exit /b 1
) else (
    echo ✅ Dependencias Flutter instaladas
)

cd ..

echo.
echo [4/4] ✅ Setup concluido com sucesso!
echo.
echo =========================================
echo           COMO EXECUTAR
echo =========================================
echo.
echo 1. BACKEND (Terminal 1):
echo    cd simple_split_backend
echo    python run.py
echo.
echo 2. FRONTEND (Terminal 2):
echo    cd simple_split_frontend
echo    flutter run
echo.
echo =========================================
echo        USUARIOS DE TESTE
echo =========================================
echo.
echo Email: pablo@example.com    ^| Senha: password123
echo Email: cecilia@example.com  ^| Senha: password123
echo Email: mariana@example.com  ^| Senha: password123
echo.
echo Codigo 2FA para teste: 123456
echo.
echo =========================================
echo       FUNCIONALIDADES PRINCIPAIS
echo =========================================
echo.
echo ✨ Interface minimalista estilo Apple
echo 👥 Gestao de grupos e divisao de despesas
echo 💰 Carteira digital integrada
echo 📊 Marketplace de recebiveis anonimo
echo 🎯 Sistema de score dinamico (0-10)
echo 📈 Insights automaticos e logs inteligentes
echo.
echo =========================================

pause