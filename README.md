# Correio Romântico 💕

Uma aplicação web para envio de cartas românticas, desenvolvida para demonstrar deploy na AWS com CI/CD.

## 🚀 Tecnologias Utilizadas

- **Backend**: Python (Flask) com SQLAlchemy
- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **Banco de Dados**: PostgreSQL
- **Deploy**: AWS EC2, Nginx
- **CI/CD**: GitHub Actions

## 📋 Funcionalidades

- ✉️ Envio de cartas românticas
- 📖 Visualização de cartas recebidas
- 💕 Interface moderna e responsiva
- 🔔 Notificações em tempo real
- 📱 Design mobile-first

## 🏗️ Arquitetura

```
├── backend/                 # API Flask
│   ├── app.py              # Aplicação principal
│   ├── requirements.txt    # Dependências Python
│   └── .env.example       # Exemplo de variáveis de ambiente
├── frontend/               # Interface web
│   ├── templates/         # Templates HTML
│   └── static/           # CSS e JavaScript
├── scripts/               # Scripts de deploy
│   ├── setup-environment.sh
│   ├── deploy.sh
│   └── dev-setup.sh
└── .github/workflows/     # CI/CD GitHub Actions
```

## 🛠️ Configuração Local

### Pré-requisitos

- Python 3.8+
- PostgreSQL (opcional, pode usar SQLite)

### Instalação

1. Clone o repositório:

```bash
git clone <seu-repositorio>
cd trabalhoAws
```

2. Execute o script de configuração:

```bash
chmod +x scripts/dev-setup.sh
./scripts/dev-setup.sh
```

3. Configure o banco de dados no arquivo `backend/.env`:

```bash
cp backend/.env.example backend/.env
# Edite as configurações conforme necessário
```

4. Execute a aplicação:

```bash
cd backend
source venv/bin/activate
python app.py
```

A aplicação estará disponível em: http://localhost:5000

## ☁️ Deploy na AWS

### Configuração dos Secrets do GitHub

Configure os seguintes secrets no seu repositório GitHub:

- `EC2_SSH_KEY`: Chave SSH privada para acesso à EC2
- `REMOTE_HOST`: IP público da instância EC2
- `REMOTE_USER`: Usuário SSH (geralmente `ubuntu`)
- `TARGET_DIR`: Diretório de destino (ex: `/home/ubuntu/trabalhoAws`)

### Deploy Automático

O deploy é automático via GitHub Actions a cada push na branch `main`. O pipeline:

1. **Testa** a aplicação (verificação de sintaxe)
2. **Copia** os arquivos para a EC2
3. **Executa** os scripts de setup e deploy
4. **Verifica** se a aplicação está funcionando

### Deploy Manual

Para deploy manual na EC2:

```bash
# Na instância EC2
git clone <seu-repositorio>
cd trabalhoAws
chmod +x scripts/setup-environment.sh scripts/deploy.sh
sudo ./scripts/setup-environment.sh
./scripts/deploy.sh
```

## 🗄️ Banco de Dados

### Modelo de Dados

**Tabela: cartas**

- `id`: Identificador único
- `remetente`: Nome do remetente
- `destinatario`: Nome do destinatário
- `titulo`: Título da carta
- `conteudo`: Conteúdo da carta
- `data_envio`: Data de envio
- `lida`: Status de leitura

### Configuração PostgreSQL na AWS

Para usar RDS PostgreSQL:

1. Crie uma instância RDS PostgreSQL
2. Configure o security group para permitir conexões na porta 5432
3. Atualize a `DATABASE_URL` no arquivo `.env`:

```
DATABASE_URL=postgresql://usuario:senha@endpoint.rds.amazonaws.com:5432/correio_romantico
```

## 🔧 API Endpoints

- `GET /` - Página principal
- `POST /api/cartas` - Enviar nova carta
- `GET /api/cartas/<destinatario>` - Listar cartas do destinatário
- `PUT /api/cartas/<id>/ler` - Marcar carta como lida
- `GET /api/health` - Health check

## 🎨 Interface

A interface foi desenvolvida com:

- Design responsivo e mobile-first
- Animações suaves com CSS3
- Paleta de cores romântica
- Tipografia elegante (Dancing Script + Poppins)
- Ícones Font Awesome

## 🚀 CI/CD Pipeline

O pipeline GitHub Actions inclui:

```yaml
1. Test Stage:
  - Setup Python
  - Install dependencies
  - Run syntax check

2. Deploy Stage (apenas branch main):
  - Copy files to EC2
  - Execute deployment scripts
  - Health check
```

## 📊 Monitoramento

### Logs da Aplicação

```bash
sudo journalctl -u correio-romantico -f
```

### Logs do Nginx

```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Status dos Serviços

```bash
sudo systemctl status correio-romantico
sudo systemctl status nginx
sudo systemctl status postgresql
```

## 🔒 Segurança

- Escape de HTML para prevenir XSS
- Validação de dados no backend
- Configuração segura do PostgreSQL
- HTTPS pronto (configurar certificado SSL)

## 🛡️ Backup

### Backup do Banco de Dados

```bash
pg_dump correio_romantico > backup.sql
```

### Restaurar Backup

```bash
psql correio_romantico < backup.sql
```

## 📈 Melhorias Futuras

- [ ] Autenticação de usuários
- [ ] Upload de imagens nas cartas
- [ ] Notificações por email
- [ ] API rate limiting
- [ ] Cache com Redis
- [ ] Containerização com Docker
- [ ] Métricas com Prometheus
- [ ] HTTPS/SSL automático

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

## 👥 Equipe

Desenvolvido com 💕 para o projeto da disciplina de Cloud Computing.

---

**Correio Romântico** - Onde o amor encontra sua voz 💕
