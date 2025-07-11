# Configuração de Secrets do GitHub

Para que o CI/CD funcione corretamente, você precisa configurar os seguintes secrets no seu repositório GitHub:

## Como configurar secrets no GitHub:

1. Vá para seu repositório no GitHub
2. Clique em **Settings** (Configurações)
3. No menu lateral, clique em **Secrets and variables** > **Actions**
4. Clique em **New repository secret**

## Secrets necessários:

### EC2_SSH_KEY

- **Descrição**: Chave SSH privada para conectar na instância EC2
- **Como obter**:
  - No console AWS, vá para EC2 > Key Pairs
  - Baixe o arquivo .pem da sua key pair
  - Copie todo o conteúdo do arquivo (incluindo BEGIN/END)
- **Exemplo**:

```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
...sua chave aqui...
-----END RSA PRIVATE KEY-----
```

### REMOTE_HOST

- **Descrição**: IP público da sua instância EC2
- **Como obter**: No console AWS EC2, copie o "Public IPv4 address"
- **Exemplo**: `3.123.45.67`

### REMOTE_USER

- **Descrição**: Usuário SSH para conectar na EC2
- **Valor padrão**: `ubuntu` (para instâncias Ubuntu)
- **Exemplo**: `ubuntu`

### TARGET_DIR

- **Descrição**: Diretório onde os arquivos serão copiados na EC2
- **Valor sugerido**: `/home/ubuntu/trabalhoAws`
- **Exemplo**: `/home/ubuntu/trabalhoAws`

## Configuração da Instância EC2

### Security Group

Certifique-se que o Security Group da sua EC2 permite:

- **SSH (porta 22)**: Para deploy via GitHub Actions
- **HTTP (porta 80)**: Para acesso à aplicação
- **HTTPS (porta 443)**: Se usar SSL (opcional)

### Preparação da Instância

Execute na sua instância EC2:

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Criar diretório de destino
mkdir -p /home/ubuntu/trabalhoAws

# Verificar conectividade SSH
ssh -i sua-chave.pem ubuntu@IP-DA-SUA-EC2
```

## Testando a Configuração

Após configurar os secrets, faça um push para a branch `main`:

```bash
git add .
git commit -m "feat: adicionar aplicação correio romântico"
git push origin main
```

Verifique no GitHub Actions se o deploy foi executado com sucesso.

## Verificação Pós-Deploy

Após o deploy, acesse sua aplicação:

- **URL**: http://IP-DA-SUA-EC2
- **Health Check**: http://IP-DA-SUA-EC2/api/health

## Troubleshooting

### Erro de SSH

- Verifique se a chave SSH está correta
- Confirme que o IP está correto
- Verifique o Security Group

### Erro de Deploy

- Verifique os logs no GitHub Actions
- Conecte via SSH e veja os logs: `sudo journalctl -u correio-romantico -f`

### Aplicação não responde

- Verifique se os serviços estão rodando:
  ```bash
  sudo systemctl status correio-romantico
  sudo systemctl status nginx
  ```
