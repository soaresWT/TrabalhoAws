#!/bin/bash

# Script para fazer backup do banco de dados
BACKUP_DIR="/var/backups/correio-romantico"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$DATE.sql"

# Criar diretório de backup se não existir
sudo mkdir -p $BACKUP_DIR

echo "🗄️ Fazendo backup do banco de dados..."

# Fazer backup
sudo -u postgres pg_dump correio_romantico > $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "✅ Backup criado com sucesso: $BACKUP_FILE"
    
    # Comprimir backup
    gzip $BACKUP_FILE
    echo "📦 Backup comprimido: $BACKUP_FILE.gz"
    
    # Manter apenas os últimos 7 backups
    find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete
    echo "🧹 Backups antigos removidos (mantendo últimos 7 dias)"
    
else
    echo "❌ Erro ao criar backup"
    exit 1
fi
