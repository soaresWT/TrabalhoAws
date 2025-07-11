#!/bin/bash

# Script de deploy da aplicação
echo "🚀 Iniciando deploy da aplicação Correio Romântico..."

# Definir variáveis
APP_DIR="/var/www/correio-romantico"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"

# Parar serviços se estiverem rodando
sudo systemctl stop correio-romantico || true
sudo systemctl stop nginx || true

# Criar diretórios necessários
sudo mkdir -p $APP_DIR
sudo mkdir -p $BACKEND_DIR
sudo mkdir -p $FRONTEND_DIR

# Copiar arquivos da aplicação
echo "📁 Copiando arquivos..."
sudo cp -r /home/ubuntu/trabalhoAws/backend/* $BACKEND_DIR/
sudo cp -r /home/ubuntu/trabalhoAws/frontend/* $FRONTEND_DIR/

# Definir permissões
sudo chown -R ubuntu:ubuntu $APP_DIR
chmod +x $BACKEND_DIR/app.py

# Criar ambiente virtual Python
echo "🐍 Configurando ambiente Python..."
cd $BACKEND_DIR
python3 -m venv venv
source venv/bin/activate

# Instalar dependências Python
pip install --upgrade pip
pip install -r requirements.txt

# Configurar variáveis de ambiente
echo "⚙️ Configurando variáveis de ambiente..."
sudo tee $BACKEND_DIR/.env > /dev/null <<EOF
DATABASE_URL=postgresql://postgres:postgres@localhost/correio_romantico
FLASK_ENV=production
FLASK_APP=app.py
AWS_REGION=us-east-1
EOF

# Configurar PostgreSQL
echo "🗄️ Configurando banco de dados..."
sudo -u postgres psql -c "CREATE DATABASE correio_romantico;" || true
sudo -u postgres psql -c "CREATE USER appuser WITH PASSWORD 'strongpassword123';" || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE correio_romantico TO appuser;" || true

# Atualizar URL do banco no .env
sudo sed -i 's/DATABASE_URL=.*/DATABASE_URL=postgresql:\/\/appuser:strongpassword123@localhost\/correio_romantico/' $BACKEND_DIR/.env

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
Environment=PATH=$BACKEND_DIR/venv/bin
ExecStart=$BACKEND_DIR/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 app:app
Restart=always

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
python3 -c "
from app import app, db
with app.app_context():
    db.create_all()
    print('Banco de dados inicializado com sucesso!')
"

# Recarregar systemd e iniciar serviços
sudo systemctl daemon-reload
sudo systemctl enable correio-romantico
sudo systemctl start correio-romantico
sudo systemctl enable nginx
sudo systemctl start nginx

# Verificar status dos serviços
echo "🔍 Verificando status dos serviços..."
sudo systemctl status correio-romantico --no-pager
sudo systemctl status nginx --no-pager

# Verificar se a aplicação está respondendo
echo "🏥 Testando aplicação..."
sleep 5
if curl -f http://localhost:5000/api/health; then
    echo "✅ Aplicação está funcionando!"
else
    echo "❌ Problema na aplicação"
    sudo journalctl -u correio-romantico --no-pager -n 20
fi

echo "🎉 Deploy concluído! A aplicação está disponível na porta 80"
echo "📝 Logs da aplicação: sudo journalctl -u correio-romantico -f"
echo "📝 Logs do Nginx: sudo tail -f /var/log/nginx/error.log"
