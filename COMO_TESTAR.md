# Como Testar a Aplicação Correio Romântico

## 🧪 Teste Local (Desenvolvimento)

### 1. Preparação do Ambiente

```bash
# Clone o repositório (se ainda não clonou)
git clone <seu-repositorio>
cd trabalhoAws

# Execute o setup automático
chmod +x scripts/dev-setup.sh
./scripts/dev-setup.sh
```

### 2. Executar Testes Automatizados

```bash
# Execute a suite de testes
chmod +x scripts/test-local.sh
./scripts/test-local.sh
```

### 3. Executar Aplicação Manualmente

```bash
# Ativar ambiente virtual
cd backend
source venv/bin/activate

# Executar aplicação
python app.py
```

Acesse: http://localhost:5000

## 🌐 Teste em Produção (AWS EC2)

### 1. Verificar Deploy

Após fazer push para branch `main`, verifique:

- GitHub Actions executou com sucesso
- Aplicação está acessível via IP da EC2

### 2. Health Check

```bash
# Conectar na EC2
ssh -i sua-chave.pem ubuntu@IP-DA-EC2

# Executar health check
cd /home/ubuntu/trabalhoAws
chmod +x scripts/health-check.sh
./scripts/health-check.sh
```

### 3. Teste Manual da API

```bash
# Health check
curl http://IP-DA-EC2/api/health

# Enviar carta
curl -X POST http://IP-DA-EC2/api/cartas \
  -H "Content-Type: application/json" \
  -d '{
    "remetente": "João",
    "destinatario": "Maria",
    "titulo": "Meu Amor",
    "conteudo": "Você é a luz da minha vida..."
  }'

# Listar cartas
curl http://IP-DA-EC2/api/cartas/Maria
```

## 🎯 Cenários de Teste

### Cenário 1: Envio de Carta

1. Acesse a aplicação
2. Clique na aba "Enviar Carta"
3. Preencha todos os campos:
   - **Seu nome**: João
   - **Para quem**: Maria
   - **Título**: "Carta de Teste"
   - **Mensagem**: "Esta é uma carta de teste..."
4. Clique em "Enviar com Amor"
5. Verifique notificação de sucesso

### Cenário 2: Visualizar Cartas

1. Clique na aba "Minhas Cartas"
2. Digite "Maria" no campo de busca
3. Clique em "Buscar"
4. Verifique se a carta aparece na lista
5. Clique na carta para abrir
6. Verifique se o conteúdo está correto

### Cenário 3: Múltiplas Cartas

1. Envie 3 cartas diferentes para "Maria"
2. Busque cartas de "Maria"
3. Verifique se todas aparecem ordenadas por data
4. Abra cada carta e verifique status "lida"

### Cenário 4: Cartas para Diferentes Pessoas

1. Envie cartas para "Ana", "Beatriz", "Carlos"
2. Busque cartas de cada pessoa
3. Verifique que cada pessoa vê apenas suas cartas

## 📱 Teste de Responsividade

### Desktop (1920x1080)

- [ ] Layout com 2 colunas
- [ ] Cards bem espaçados
- [ ] Botões com hover effects
- [ ] Modal centralizado

### Tablet (768x1024)

- [ ] Layout adaptativo
- [ ] Botões touch-friendly
- [ ] Formulários legíveis
- [ ] Modal responsivo

### Mobile (375x667)

- [ ] Layout em coluna única
- [ ] Tabs verticais
- [ ] Campos de entrada grandes
- [ ] Navegação otimizada

## 🔍 Teste de Performance

### Load Test Básico

```bash
# Instalar ferramenta (na EC2)
sudo apt install apache2-utils

# Teste com 100 requisições simultâneas
ab -n 1000 -c 100 http://localhost/api/health

# Teste de envio de cartas
ab -n 100 -c 10 -p carta.json -T application/json http://localhost/api/cartas
```

### Métricas Esperadas

- **Response Time**: < 200ms para API
- **Uptime**: > 99%
- **Concurrent Users**: Suportar 100+ usuários
- **Database**: < 50ms para queries

## 🛡️ Teste de Segurança

### 1. Validação de Dados

Teste enviar carta com dados inválidos:

```json
{
  "remetente": "",
  "destinatario": "",
  "titulo": "",
  "conteudo": ""
}
```

**Esperado**: Erro 400 com mensagem clara

### 2. XSS Protection

Teste enviar carta com HTML/JavaScript:

```json
{
  "remetente": "<script>alert('XSS')</script>",
  "destinatario": "Test",
  "titulo": "<img src=x onerror=alert('XSS')>",
  "conteudo": "Normal text"
}
```

**Esperado**: HTML escapado na exibição

### 3. SQL Injection

Teste buscar cartas com caracteres especiais:

- `'; DROP TABLE cartas; --`
- `' OR '1'='1`

**Esperado**: Query segura via SQLAlchemy

## 🐛 Teste de Erros

### 1. Banco Indisponível

```bash
# Parar PostgreSQL
sudo systemctl stop postgresql

# Testar aplicação
curl http://localhost/api/health
```

**Esperado**: Erro 500 ou graceful degradation

### 2. Disco Cheio

```bash
# Simular disco cheio (cuidado!)
dd if=/dev/zero of=/tmp/big-file bs=1M count=1000

# Testar envio de carta
# Esperado: Erro apropriado
```

### 3. Rede Instável

```bash
# Simular latência alta
sudo tc qdisc add dev eth0 root netem delay 1000ms

# Testar aplicação
# Esperado: Timeouts apropriados
```

## 📊 Monitoramento Durante Testes

### 1. Logs em Tempo Real

```bash
# Terminal 1: Logs da aplicação
sudo journalctl -u correio-romantico -f

# Terminal 2: Logs do Nginx
sudo tail -f /var/log/nginx/access.log

# Terminal 3: Recursos do sistema
htop
```

### 2. Métricas de Sistema

```bash
# CPU e Memória
watch -n 1 'free -h && uptime'

# Conexões de rede
watch -n 1 'netstat -an | grep :80 | wc -l'

# Espaço em disco
df -h
```

## ✅ Checklist de Teste

### Funcionalidade

- [ ] Envio de carta com sucesso
- [ ] Visualização de cartas
- [ ] Marcar carta como lida
- [ ] Busca por destinatário
- [ ] Ordenação por data
- [ ] Notificações funcionando

### Interface

- [ ] Design responsivo
- [ ] Animações suaves
- [ ] Carregamento rápido
- [ ] Botões funcionais
- [ ] Modal de carta
- [ ] Validação de formulário

### Backend

- [ ] API endpoints funcionando
- [ ] Banco de dados persistindo
- [ ] Health check OK
- [ ] Logs informativos
- [ ] Tratamento de erros

### Deploy

- [ ] GitHub Actions executando
- [ ] Aplicação acessível na EC2
- [ ] Nginx proxy funcionando
- [ ] SSL configurado (se aplicável)
- [ ] Backup automático

### Performance

- [ ] Response time < 200ms
- [ ] Suporte a 100+ usuários
- [ ] Cache funcionando
- [ ] Compressão ativa

### Segurança

- [ ] XSS protection
- [ ] Input validation
- [ ] SQL injection protection
- [ ] CORS configurado
- [ ] Headers de segurança

## 🚨 Teste de Recuperação

### 1. Falha de Deploy

```bash
# Simular falha e testar rollback
git revert HEAD
git push origin main
# Verificar se aplicação volta ao estado anterior
```

### 2. Corrupção de Banco

```bash
# Restaurar do backup
./scripts/backup.sh  # Criar backup primeiro
# Simular problema
# Restaurar backup
```

### 3. Alta Carga

```bash
# Teste de stress
ab -n 10000 -c 100 http://IP-DA-EC2/
# Verificar se aplicação se recupera
```

---

**💡 Dica**: Execute os testes em ordem e documente os resultados. Em caso de falha, verifique os logs antes de prosseguir.
