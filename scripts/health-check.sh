#!/bin/bash

# Script para verificar saúde da aplicação
echo "🏥 Verificando saúde da aplicação Correio Romântico..."

# Verificar se os serviços estão rodando
services=("correio-romantico" "nginx" "postgresql")

for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "✅ $service está rodando"
    else
        echo "❌ $service NÃO está rodando"
        sudo systemctl status $service --no-pager
    fi
done

# Verificar conectividade HTTP
echo ""
echo "🌐 Testando conectividade HTTP..."

if curl -f -s http://localhost/api/health > /dev/null; then
    echo "✅ API respondendo corretamente"
    echo "📊 Status da API:"
    curl -s http://localhost/api/health | python3 -m json.tool
else
    echo "❌ API não está respondendo"
fi

# Verificar espaço em disco
echo ""
echo "💾 Verificando espaço em disco..."
df -h / | tail -1 | awk '{print "Uso do disco: " $5 " de " $2}'

# Verificar memória
echo ""
echo "🧠 Verificando uso de memória..."
free -h | grep "Mem:" | awk '{print "Memória: " $3 " / " $2 " (" int($3/$2 * 100) "%)"}'

# Verificar logs recentes de erro
echo ""
echo "📝 Últimos logs de erro (se houver):"
sudo journalctl -u correio-romantico --since "10 minutes ago" --no-pager -q
