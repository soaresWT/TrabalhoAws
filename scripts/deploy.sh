#!/bin/bash

# Script de deploy da aplicação
echo "🚀 Iniciando deploy da aplicação Correio Romântico..."

# Definir variáveis
APP_DIR="/var/www/correio-romantico"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"
SOURCE_DIR="/home/ubuntu"

# Parar serviços se estiverem rodando
sudo systemctl stop correio-romantico || true
sudo systemctl stop nginx || true

# Criar diretórios necessários
sudo mkdir -p $APP_DIR
sudo mkdir -p $BACKEND_DIR
sudo mkdir -p $FRONTEND_DIR

# Copiar arquivos da aplicação
echo "📁 Copiando arquivos..."

# Verificar se os diretórios de origem existem
if [ ! -d "$SOURCE_DIR/backend" ]; then
    echo "❌ Diretório $SOURCE_DIR/backend não encontrado!"
    echo "Verificando estrutura de diretórios..."
    ls -la $SOURCE_DIR/
    exit 1
fi

if [ ! -d "$SOURCE_DIR/frontend" ]; then
    echo "❌ Diretório $SOURCE_DIR/frontend não encontrado!"
    echo "Verificando estrutura de diretórios..."
    ls -la $SOURCE_DIR/
    exit 1
fi

sudo cp -r $SOURCE_DIR/backend/* $BACKEND_DIR/
sudo cp -r $SOURCE_DIR/frontend/* $FRONTEND_DIR/

# Definir permissões
sudo chown -R ubuntu:ubuntu $APP_DIR
chmod +x $BACKEND_DIR/app.py

# Garantir que o diretório do banco SQLite tenha permissões corretas
sudo mkdir -p $BACKEND_DIR/instance
sudo chown -R ubuntu:ubuntu $BACKEND_DIR/instance
chmod 755 $BACKEND_DIR/instance

# Criar ambiente virtual Python
echo "🐍 Configurando ambiente Python..."
cd $BACKEND_DIR

# Remover ambiente virtual antigo se existir
rm -rf venv

# Criar novo ambiente virtual como usuário ubuntu
python3 -m venv venv
source venv/bin/activate

# Garantir permissões corretas do ambiente virtual
sudo chown -R ubuntu:ubuntu venv

# Instalar dependências Python
echo "📦 Instalando dependências Python..."
pip install --upgrade pip

# Verificar se requirements.txt existe
if [ ! -f "requirements.txt" ]; then
    echo "❌ Arquivo requirements.txt não encontrado!"
    ls -la $BACKEND_DIR/
    exit 1
fi

echo "📋 Conteúdo do requirements.txt:"
cat requirements.txt

echo "📦 Instalando cada dependência..."
pip install -r requirements.txt --no-cache-dir

# Verificar se a instalação foi bem-sucedida
if [ $? -eq 0 ]; then
    echo "✅ Dependências instaladas com sucesso!"
    echo "📋 Pacotes instalados:"
    pip list | grep -E "Flask|gunicorn|python-dotenv|SQLAlchemy"
else
    echo "❌ Erro ao instalar dependências!"
    echo "Tentando instalação individual das dependências críticas..."
    pip install Flask Flask-CORS Flask-SQLAlchemy python-dotenv gunicorn requests
    if [ $? -eq 0 ]; then
        echo "✅ Dependências críticas instaladas com sucesso!"
    else
        echo "❌ Falha crítica na instalação de dependências!"
        exit 1
    fi
fi

# Configurar variáveis de ambiente
echo "⚙️ Configurando variáveis de ambiente..."
sudo tee $BACKEND_DIR/.env > /dev/null <<EOF
DATABASE_URL=sqlite:////var/www/correio-romantico/backend/correio_romantico.db
FLASK_ENV=production
FLASK_APP=app.py
AWS_REGION=us-east-1
EOF

# Configurar PostgreSQL (comentado para usar SQLite)
# echo "🗄️ Configurando banco de dados..."
# sudo -u postgres psql -c "CREATE DATABASE correio_romantico;" || true
# sudo -u postgres psql -c "CREATE USER appuser WITH PASSWORD 'strongpassword123';" || true
# sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE correio_romantico TO appuser;" || true

# Atualizar URL do banco no .env (usando SQLite)
# sudo sed -i 's/DATABASE_URL=.*/DATABASE_URL=postgresql:\/\/appuser:strongpassword123@localhost\/correio_romantico/' $BACKEND_DIR/.env

# Criar arquivo de serviço systemd
echo "🔧 Configurando serviço systemd..."
sudo tee /etc/systemd/system/correio-romantico.service > /dev/null <<EOF
[Unit]
Description=Correio Romântico Flask App
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=$BACKEND_DIR
Environment=PATH=$BACKEND_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin
EnvironmentFile=$BACKEND_DIR/.env
ExecStart=$BACKEND_DIR/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 --timeout 120 --access-logfile - --error-logfile - app:app
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Configurar Nginx
echo "🌐 Configurando Nginx..."
sudo tee /etc/nginx/sites-available/correio-romantico > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    location /static/ {
        alias $FRONTEND_DIR/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Ativar site no Nginx
sudo ln -sf /etc/nginx/sites-available/correio-romantico /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Testar configuração do Nginx
sudo nginx -t

# Inicializar banco de dados
echo "🗄️ Inicializando banco de dados..."
cd $BACKEND_DIR
source venv/bin/activate

# Verificar se consegue importar a aplicação
echo "🔍 Testando importação da aplicação..."
python3 -c "
from app import app, db
with app.app_context():
    db.create_all()
    print('Banco de dados inicializado com sucesso!')
"

# Verificar se o gunicorn funciona
echo "🔍 Testando gunicorn..."
which gunicorn
gunicorn --version

# Recarregar systemd e iniciar serviços
sudo systemctl daemon-reload
sudo systemctl enable correio-romantico

echo "🔍 Iniciando serviço..."
sudo systemctl start correio-romantico

# Aguardar um pouco para o serviço iniciar
sleep 3

# Verificar se iniciou corretamente
if sudo systemctl is-active --quiet correio-romantico; then
    echo "✅ Serviço correio-romantico iniciado com sucesso"
else
    echo "❌ Falha ao iniciar o serviço correio-romantico"
    echo "Logs do serviço:"
    sudo journalctl -u correio-romantico --no-pager -n 10
fi
sudo systemctl enable nginx
sudo systemctl start nginx

# Verificar status dos serviços
echo "🔍 Verificando status dos serviços..."
sudo systemctl status correio-romantico --no-pager
sudo systemctl status nginx --no-pager

# Verificar se a aplicação está respondendo
echo "🏥 Testando aplicação..."
sleep 5
if curl -f http://localhost/api/health; then
    echo "✅ Aplicação está funcionando!"
else
    echo "❌ Problema na aplicação"
    echo "Testando diretamente na porta 5000..."
    curl -f http://localhost:5000/api/health || true
    echo "Logs da aplicação:"
    sudo journalctl -u correio-romantico --no-pager -n 20
fi

echo "🎉 Deploy concluído! A aplicação está disponível na porta 80"
echo "📝 Logs da aplicação: sudo journalctl -u correio-romantico -f"
echo "📝 Logs do Nginx: sudo tail -f /var/log/nginx/error.log"
