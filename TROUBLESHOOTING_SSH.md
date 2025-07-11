# 🔧 Troubleshooting GitHub Actions - Correio Romântico

## ❌ Erro: "Permission denied (publickey)"

Este erro indica problema com a configuração da chave SSH. Siga este guia para resolver:

### 1. Verificar a Chave SSH

#### Formato Correto da Chave

A chave SSH deve estar no formato completo:

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAA...
...toda a chave aqui...
-----END OPENSSH PRIVATE KEY-----
```

**OU** no formato RSA:

```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1234567890abcdef...
...toda a chave aqui...
-----END RSA PRIVATE KEY-----
```

#### Como Obter a Chave Correta

1. No console AWS, vá para **EC2 > Key Pairs**
2. Encontre sua key pair
3. Se não tiver o arquivo .pem, crie uma nova key pair
4. Baixe o arquivo .pem
5. Copie **TODO** o conteúdo (incluindo BEGIN/END)

### 2. Configurar Secrets no GitHub

#### Passo a Passo:

1. Vá para seu repositório no GitHub
2. **Settings** > **Secrets and variables** > **Actions**
3. Configure os secrets:

**EC2_SSH_KEY**:

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAA...
[COLE TODA A CHAVE AQUI SEM MODIFICAR]
-----END OPENSSH PRIVATE KEY-----
```

**REMOTE_HOST**:

```
18.123.45.67
```

(Apenas o IP, sem protocolo)

**REMOTE_USER**:

```
ubuntu
```

(Para instâncias Ubuntu)

**TARGET_DIR**:

```
/home/ubuntu/trabalhoAws
```

### 3. Verificar Security Group da EC2

Certifique-se que o Security Group permite:

- **SSH (porta 22)** de qualquer lugar (0.0.0.0/0)
- **HTTP (porta 80)** de qualquer lugar (0.0.0.0/0)

### 4. Testar Conexão SSH Manualmente

```bash
# No seu computador local
ssh -i sua-chave.pem ubuntu@SEU-IP-EC2

# Se funcionar, a chave está correta
# Se não funcionar, há problema na configuração
```

### 5. Verificar Permissões da Chave

```bash
# A chave deve ter permissões corretas
chmod 600 sua-chave.pem
ssh -i sua-chave.pem ubuntu@SEU-IP-EC2
```

### 6. Soluções Alternativas

#### Opção 1: Recriar Key Pair

1. No AWS EC2 > Key Pairs > Create key pair
2. Nome: `correio-romantico-key`
3. Formato: `.pem`
4. Baixe e configure no GitHub
5. **IMPORTANTE**: Associe a nova key à sua instância EC2

#### Opção 2: Usar GitHub CLI (gh)

```bash
# Configurar secrets via CLI
gh secret set EC2_SSH_KEY < sua-chave.pem
gh secret set REMOTE_HOST --body "SEU-IP"
gh secret set REMOTE_USER --body "ubuntu"
gh secret set TARGET_DIR --body "/home/ubuntu/trabalhoAws"
```

### 7. Debug do GitHub Actions

#### Ver Logs Detalhados:

1. Vá para **Actions** no seu repositório
2. Clique no workflow que falhou
3. Expanda "Copy files to EC2"
4. Procure por mensagens de erro específicas

#### Logs Úteis:

```
✅ [SSH] key added to `.ssh` dir
❌ Permission denied (publickey) <- PROBLEMA AQUI
```

### 8. Workflow de Debug

Adicione este step para debug:

```yaml
- name: Debug SSH Connection
  uses: appleboy/ssh-action@v1.0.0
  with:
    host: ${{ secrets.REMOTE_HOST }}
    username: ${{ secrets.REMOTE_USER }}
    key: ${{ secrets.EC2_SSH_KEY }}
    script: |
      echo "Conexão SSH funcionando!"
      whoami
      pwd
      ls -la
```

### 9. Checklist Final

- [ ] Chave SSH está completa (com BEGIN/END)
- [ ] IP da EC2 está correto e público
- [ ] Security Group permite SSH (porta 22)
- [ ] Usuário é 'ubuntu' para instâncias Ubuntu
- [ ] Diretório target existe na EC2
- [ ] Instância EC2 está rodando

### 10. Formato Correto dos Secrets

**Exemplo de configuração que funciona:**

```bash
# EC2_SSH_KEY (exemplo)
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAlwAAAAdzc2gtcn
NhAAAAAwEAAQAAAIEAyv8kM2w... [chave completa aqui]
-----END OPENSSH PRIVATE KEY-----

# REMOTE_HOST
3.123.45.67

# REMOTE_USER
ubuntu

# TARGET_DIR
/home/ubuntu/trabalhoAws
```

### 11. Teste Rápido

Após configurar os secrets, teste com este workflow simples:

```yaml
name: Test SSH Connection
on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Test SSH
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.REMOTE_HOST }}
          username: ${{ secrets.REMOTE_USER }}
          key: ${{ secrets.EC2_SSH_KEY }}
          script: echo "SSH funcionando!"
```

### 🚨 Se Nada Funcionar

1. **Recrie a instância EC2** com nova key pair
2. **Certifique-se** que está usando Ubuntu 22.04 LTS
3. **Configure** o Security Group corretamente
4. **Teste** SSH manualmente primeiro
5. **Verifique** se não há caracteres especiais na chave

### 📞 Debug Avançado

Se ainda não funcionar, adicione este debug:

```yaml
- name: Debug Environment
  run: |
    echo "Host: ${{ secrets.REMOTE_HOST }}"
    echo "User: ${{ secrets.REMOTE_USER }}"
    echo "Key length: $(echo '${{ secrets.EC2_SSH_KEY }}' | wc -c)"
    echo "Key starts with: $(echo '${{ secrets.EC2_SSH_KEY }}' | head -1)"
```

---

## ✅ Verificação Final

Quando tudo estiver funcionando, você verá:

```
✅ [SSH] key added to `.ssh` dir
✅️ [CLI] Rsync exists
✅ [Rsync] Rsync completed successfully
```

**Lembre-se**: A chave SSH é sensível! Nunca a coloque no código ou logs públicos.
