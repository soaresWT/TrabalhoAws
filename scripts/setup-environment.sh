#!/bin/bash

# Script de setup para o ambiente de produção
echo "🚀 Configurando ambiente de produção..."

# Atualizar sistema
sudo apt-get update
sudo apt-get upgrade -y

# Instalar Python 3 e pip se não estiverem instalados
sudo apt-get install -y python3 python3-pip python3-venv

# Instalar PostgreSQL e dependências de desenvolvimento
echo "🗄️ Instalando PostgreSQL..."
sudo apt-get install -y postgresql postgresql-contrib postgresql-server-dev-all libpq-dev

# Instalar Nginx
sudo apt-get install -y nginx

# Criar usuário para a aplicação se não existir
if ! id "appuser" &>/dev/null; then
    sudo useradd -m -s /bin/bash appuser
    sudo usermod -aG sudo appuser
fi

# Criar diretório da aplicação
sudo mkdir -p /var/www/correio-romantico
sudo chown appuser:appuser /var/www/correio-romantico

echo "✅ Setup do ambiente concluído!"
