#!/bin/bash

# Script para testar a aplicação localmente
echo "🧪 Testando aplicação Correio Romântico localmente..."

# Verificar se estamos no diretório correto
if [ ! -f "backend/app.py" ]; then
    echo "❌ Execute este script a partir da raiz do projeto"
    exit 1
fi

# Configurar ambiente se necessário
if [ ! -d "backend/venv" ]; then
    echo "🔧 Configurando ambiente pela primeira vez..."
    ./scripts/dev-setup.sh
fi

# Ativar ambiente virtual
cd backend
source venv/bin/activate

# Verificar dependências
echo "📦 Verificando dependências..."
pip install -r requirements.txt > /dev/null 2>&1

# Configurar banco SQLite para teste
export DATABASE_URL="sqlite:///correio_romantico_test.db"
echo "🗄️ Usando banco SQLite para teste"

# Inicializar banco
echo "🏗️ Inicializando banco de dados..."
python3 -c "
from app import app, db
with app.app_context():
    db.create_all()
    print('✅ Banco inicializado!')
"

# Testar sintaxe
echo "🔍 Verificando sintaxe do código..."
python3 -m py_compile app.py
if [ $? -eq 0 ]; then
    echo "✅ Sintaxe OK"
else
    echo "❌ Erro de sintaxe"
    exit 1
fi

# Testar importações
echo "📥 Testando importações..."
python3 -c "
try:
    from app import app, db, Carta
    print('✅ Importações OK')
except ImportError as e:
    print(f'❌ Erro de importação: {e}')
    exit(1)
"

# Testar criação de carta
echo "💕 Testando funcionalidade básica..."
python3 -c "
from app import app, db, Carta
import requests
import threading
import time

def run_server():
    app.run(host='127.0.0.1', port=5001, debug=False)

# Iniciar servidor em thread separada
server_thread = threading.Thread(target=run_server, daemon=True)
server_thread.start()

# Aguardar servidor iniciar
time.sleep(3)

try:
    # Testar health check
    response = requests.get('http://127.0.0.1:5001/api/health', timeout=5)
    if response.status_code == 200:
        print('✅ Health check OK')
    else:
        print('❌ Health check falhou')
        exit(1)
    
    # Testar página principal
    response = requests.get('http://127.0.0.1:5001/', timeout=5)
    if response.status_code == 200:
        print('✅ Página principal OK')
    else:
        print('❌ Página principal falhou')
        exit(1)
    
    # Testar envio de carta
    carta_data = {
        'remetente': 'João Test',
        'destinatario': 'Maria Test',
        'titulo': 'Carta de Teste',
        'conteudo': 'Esta é uma carta de teste para verificar se a aplicação está funcionando.'
    }
    
    response = requests.post('http://127.0.0.1:5001/api/cartas', json=carta_data, timeout=5)
    if response.status_code == 201:
        print('✅ Envio de carta OK')
    else:
        print(f'❌ Envio de carta falhou: {response.status_code}')
        exit(1)
    
    # Testar listagem de cartas
    response = requests.get('http://127.0.0.1:5001/api/cartas/Maria Test', timeout=5)
    if response.status_code == 200:
        cartas = response.json()
        if len(cartas) > 0:
            print('✅ Listagem de cartas OK')
        else:
            print('❌ Nenhuma carta encontrada')
            exit(1)
    else:
        print(f'❌ Listagem de cartas falhou: {response.status_code}')
        exit(1)
    
    print('🎉 Todos os testes passaram!')
    
except Exception as e:
    print(f'❌ Erro durante os testes: {e}')
    exit(1)
"

cd ..

echo ""
echo "✅ Teste completo finalizado!"
echo ""
echo "Para executar a aplicação manualmente:"
echo "1. cd backend"
echo "2. source venv/bin/activate"
echo "3. python app.py"
echo ""
echo "Acesse: http://localhost:5000"
