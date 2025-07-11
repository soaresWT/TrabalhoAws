# Documentação Técnica - Correio Romântico

## Visão Geral da Arquitetura

O Correio Romântico é uma aplicação web full-stack que permite aos usuários enviar e receber cartas românticas. A aplicação foi projetada seguindo uma arquitetura de microserviços simples, separando claramente as responsabilidades entre frontend e backend.

## Stack Tecnológica

### Backend

- **Linguagem**: Python 3.9+
- **Framework**: Flask 2.3.3
- **ORM**: SQLAlchemy 3.0.5
- **Banco de Dados**: PostgreSQL (produção) / SQLite (desenvolvimento)
- **WSGI Server**: Gunicorn 21.2.0
- **CORS**: Flask-CORS 4.0.0

### Frontend

- **HTML5**: Estrutura semântica
- **CSS3**: Estilos modernos com Flexbox/Grid
- **JavaScript**: Vanilla ES6+
- **Fontes**: Google Fonts (Dancing Script, Poppins)
- **Ícones**: Font Awesome 6.0.0

### Infraestrutura

- **Servidor Web**: Nginx (proxy reverso)
- **Cloud**: AWS EC2
- **CI/CD**: GitHub Actions
- **Monitoramento**: Systemd + Journalctl

## Modelo de Dados

### Entidade: Carta

```python
class Carta(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    remetente = db.Column(db.String(100), nullable=False)
    destinatario = db.Column(db.String(100), nullable=False)
    titulo = db.Column(db.String(200), nullable=False)
    conteudo = db.Column(db.Text, nullable=False)
    data_envio = db.Column(db.DateTime, default=datetime.utcnow)
    lida = db.Column(db.Boolean, default=False)
```

**Índices Recomendados**:

- `idx_destinatario` em `destinatario` (para busca rápida)
- `idx_data_envio` em `data_envio` (para ordenação)

## API REST

### Base URL

- **Desenvolvimento**: `http://localhost:5000`
- **Produção**: `http://SEU-IP-EC2`

### Endpoints

#### GET /

**Descrição**: Página principal da aplicação
**Resposta**: HTML da interface

#### POST /api/cartas

**Descrição**: Enviar nova carta
**Payload**:

```json
{
  "remetente": "string",
  "destinatario": "string",
  "titulo": "string",
  "conteudo": "string"
}
```

**Resposta**:

```json
{
  "message": "Carta enviada com sucesso!",
  "carta": {
    /* objeto carta */
  }
}
```

#### GET /api/cartas/{destinatario}

**Descrição**: Listar cartas de um destinatário
**Parâmetros**:

- `destinatario` (string): Nome do destinatário
  **Resposta**: Array de objetos carta

#### PUT /api/cartas/{id}/ler

**Descrição**: Marcar carta como lida
**Parâmetros**:

- `id` (integer): ID da carta
  **Resposta**:

```json
{
  "message": "Carta marcada como lida"
}
```

#### GET /api/health

**Descrição**: Health check da aplicação
**Resposta**:

```json
{
  "status": "OK",
  "timestamp": "2025-01-10T12:00:00.000Z"
}
```

## Segurança

### Validação de Dados

- Validação no backend de todos os campos obrigatórios
- Escape de HTML no frontend para prevenir XSS
- Sanitização de strings SQL via SQLAlchemy ORM

### CORS

- Configurado para permitir requisições do frontend
- Headers apropriados para API REST

### Recomendações para Produção

- [ ] Implementar rate limiting
- [ ] Adicionar autenticação JWT
- [ ] Configurar HTTPS com certificado SSL
- [ ] Implementar logs de auditoria
- [ ] Adicionar middleware de segurança

## Performance

### Otimizações Implementadas

- Compressão CSS/JS via Nginx
- Cache de arquivos estáticos (30 dias)
- Conexão persistente com banco de dados
- Lazy loading de imagens (quando implementado)

### Métricas Recomendadas

- Response time das APIs (< 200ms)
- Uptime da aplicação (> 99.9%)
- Uso de CPU/Memória
- Conexões simultâneas

## Monitoramento e Logs

### Logs da Aplicação

```bash
# Ver logs em tempo real
sudo journalctl -u correio-romantico -f

# Ver logs das últimas 24h
sudo journalctl -u correio-romantico --since "24 hours ago"
```

### Logs do Nginx

```bash
# Access logs
sudo tail -f /var/log/nginx/access.log

# Error logs
sudo tail -f /var/log/nginx/error.log
```

### Health Check Automatizado

Script `scripts/health-check.sh` verifica:

- Status dos serviços (systemd)
- Conectividade HTTP
- Uso de recursos (CPU, memória, disco)
- Logs de erro recentes

## Deploy e CI/CD

### Pipeline GitHub Actions

1. **Test Stage**:

   - Setup Python 3.9
   - Instalar dependências
   - Verificar sintaxe Python
   - Executar testes básicos

2. **Deploy Stage** (apenas branch main):
   - Copiar arquivos para EC2 via SSH
   - Executar script de setup do ambiente
   - Executar script de deploy
   - Health check pós-deploy

### Scripts de Deploy

#### setup-environment.sh

- Atualiza sistema operacional
- Instala Python, PostgreSQL, Nginx
- Cria usuário da aplicação
- Configura estrutura de diretórios

#### deploy.sh

- Para serviços existentes
- Copia arquivos da aplicação
- Instala dependências Python
- Configura banco de dados
- Configura serviços systemd
- Inicia aplicação

### Rollback

Em caso de problemas:

```bash
# Reverter para versão anterior via Git
git checkout HEAD~1
./scripts/deploy.sh

# Ou restaurar backup do banco
gunzip -c /var/backups/correio-romantico/backup_YYYYMMDD.sql.gz | psql correio_romantico
```

## Configuração de Ambiente

### Variáveis de Ambiente (.env)

```bash
DATABASE_URL=postgresql://user:pass@host:5432/db
FLASK_ENV=production
FLASK_APP=app.py
AWS_REGION=us-east-1
```

### Configuração Nginx

```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /static/ {
        alias /path/to/frontend/static/;
        expires 30d;
    }
}
```

## Backup e Recuperação

### Backup Automático

Script `scripts/backup.sh`:

- Executa `pg_dump` do PostgreSQL
- Comprime arquivo SQL
- Mantém últimos 7 backups
- Pode ser agendado via crontab

### Configurar Backup Automático

```bash
# Adicionar ao crontab
sudo crontab -e

# Backup diário às 2h
0 2 * * * /home/ubuntu/trabalhoAws/scripts/backup.sh
```

### Restaurar Backup

```bash
# Restaurar backup específico
gunzip -c backup_20250110_020000.sql.gz | psql correio_romantico
```

## Troubleshooting

### Problemas Comuns

#### Aplicação não inicia

```bash
# Verificar logs
sudo journalctl -u correio-romantico --no-pager

# Verificar configuração
cd /var/www/correio-romantico/backend
source venv/bin/activate
python app.py
```

#### Banco não conecta

```bash
# Verificar PostgreSQL
sudo systemctl status postgresql

# Testar conexão
psql -h localhost -U appuser -d correio_romantico
```

#### Nginx retorna 502

```bash
# Verificar se app está rodando
curl http://localhost:5000/api/health

# Verificar configuração Nginx
sudo nginx -t
```

## Testes

### Testes Locais

```bash
# Executar suite de testes
./scripts/test-local.sh
```

### Testes de Carga (Recomendado)

```bash
# Instalar Apache Bench
sudo apt install apache2-utils

# Teste de carga básico
ab -n 1000 -c 10 http://localhost/api/health
```

## Evolução e Roadmap

### Próximas Versões

1. **v2.0**: Autenticação de usuários
2. **v2.1**: Upload de imagens
3. **v2.2**: Notificações em tempo real
4. **v3.0**: Mobile app (React Native)

### Melhorias de Infraestrutura

- Containerização com Docker
- Orquestração com Kubernetes
- CDN para assets estáticos
- Load balancing para alta disponibilidade
- Métricas com Prometheus + Grafana
