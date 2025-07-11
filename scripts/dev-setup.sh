#!/bin/bash

# Script para desenvolvimento local
echo "🔧 Configurando ambiente de desenvolvimento local..."

# Verificar se Python está instalado
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 não encontrado. Por favor, instale Python 3."
    exit 1
fi

# Criar ambiente virtual se não existir
if [ ! -d "backend/venv" ]; then
    echo "🐍 Criando ambiente virtual Python..."
    cd backend
    python3 -m venv venv
    cd ..
fi

# Ativar ambiente virtual e instalar dependências
echo "📦 Instalando dependências..."
cd backend
source venv/bin/activate
pip install --upgrade pip

# Tentar instalar requirements completo, se falhar usar versão dev
if pip install -r requirements.txt; then
    echo "✅ Dependências completas instaladas"
else
    echo "⚠️ Falha com PostgreSQL, instalando versão de desenvolvimento..."
    pip install -r requirements-dev.txt
fi

cd ..

# Configurar variáveis de ambiente para desenvolvimento
if [ ! -f "backend/.env" ]; then
    echo "⚙️ Configurando variáveis de ambiente..."
    cp backend/.env.example backend/.env
    echo "✏️ Edite o arquivo backend/.env com suas configurações de banco de dados"
fi

# Verificar se PostgreSQL está rodando (opcional para desenvolvimento)
if command -v pg_isready &> /dev/null; then
    if pg_isready -q; then
        echo "✅ PostgreSQL está rodando"
    else
        echo "⚠️ PostgreSQL não está rodando. Inicie o serviço ou use SQLite para desenvolvimento"
        # Configurar SQLite para desenvolvimento se PostgreSQL não estiver disponível
        echo "DATABASE_URL=sqlite:///correio_romantico.db" > backend/.env
    fi
else
    echo "⚠️ PostgreSQL não encontrado. Usando SQLite para desenvolvimento"
    echo "DATABASE_URL=sqlite:///correio_romantico.db" > backend/.env
fi

echo "🎉 Ambiente de desenvolvimento configurado!"
echo ""
echo "Para executar a aplicação:"
echo "1. cd backend"
echo "2. source venv/bin/activate"
echo "3. python app.py"
echo ""
echo "A aplicação estará disponível em: http://localhost:5000"
