# 09 - Bônus: FTP Server

[Voltar ao Índice](./00-INDICE.md) | [Anterior: Redis](./08-BONUS-REDIS.md)

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Dockerfile](#2-dockerfile)
3. [Configuração vsftpd](#3-configuração-vsftpd)
4. [Script de Inicialização](#4-script-de-inicialização)
5. [Docker Compose](#5-docker-compose)
6. [Testes e Validação](#6-testes-e-validação)

---

## 1. Visão Geral

O servidor FTP permite:

- Upload/download de arquivos do WordPress
- Acesso aos arquivos do volume WordPress
- Gerenciamento de temas e plugins via FTP

### Arquitetura

```
┌────────────────┐
│   FTP Client   │
│  (FileZilla)   │
└───────┬────────┘
        │
        │ Port 21 + Passive Ports
        ▼
┌───────────────────────────────────────┐
│               vsftpd                   │
│                                        │
│   /var/www/html (volume WordPress)     │
└───────────────────────────────────────┘
```

### Arquivos a Criar

```
srcs/requirements/bonus/ftp/
├── Dockerfile
├── .dockerignore
├── conf/
│   └── vsftpd.conf
└── tools/
    └── init.sh
```

---

## 2. Dockerfile

### srcs/requirements/bonus/ftp/Dockerfile

```dockerfile
# ============================================================================ #
#                             FTP SERVER DOCKERFILE                            #
#                                                                              #
#  Base: Debian Bullseye (penúltima versão estável)                           #
#  Serviço: vsftpd (Very Secure FTP Daemon)                                    #
# ============================================================================ #

FROM debian:bullseye

# Instalar vsftpd e utilitários
# procps: necessário para verificação de PID 1 (ps)
RUN apt-get update && apt-get install -y --no-install-recommends \
    vsftpd \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Criar diretórios necessários
RUN mkdir -p /var/run/vsftpd/empty \
    && mkdir -p /var/log/vsftpd \
    && mkdir -p /etc/vsftpd

# Copiar configuração
COPY conf/vsftpd.conf /etc/vsftpd.conf

# Copiar script de inicialização
COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

# Expor portas
# 21: FTP control
# 21100-21110: Passive mode data
EXPOSE 21
EXPOSE 21100-21110

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD pgrep vsftpd > /dev/null || exit 1

# Iniciar vsftpd
ENTRYPOINT ["/usr/local/bin/init.sh"]
```

---

## 3. Configuração vsftpd

### srcs/requirements/bonus/ftp/conf/vsftpd.conf

```conf
# ============================================================================ #
#                         VSFTPD CONFIGURATION                                 #
# ============================================================================ #

# Não rodar em background
background=NO

# Escutar IPv4
listen=YES
listen_ipv6=NO

# Permitir usuários locais
local_enable=YES

# Permitir escrita
write_enable=YES

# Máscara de criação de arquivos
local_umask=022

# Habilitar mensagens de diretório
dirmessage_enable=YES

# Mostrar timestamps locais
use_localtime=YES

# Logging
xferlog_enable=YES
xferlog_std_format=YES
log_ftp_protocol=YES
vsftpd_log_file=/var/log/vsftpd/vsftpd.log

# Porta de conexão
connect_from_port_20=YES

# Timeout
idle_session_timeout=300
data_connection_timeout=120

# Modo passivo
pasv_enable=YES
pasv_min_port=21100
pasv_max_port=21110
pasv_address=127.0.0.1

# Não permitir login anônimo
anonymous_enable=NO

# Chroot - manter usuários em seus diretórios
chroot_local_user=YES
allow_writeable_chroot=YES

# Usar lista de usuários
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO

# Diretório seguro
secure_chroot_dir=/var/run/vsftpd/empty

# PAM
pam_service_name=vsftpd

# Diretório local root
local_root=/var/www/html

# Suporte a caracteres UTF-8
utf8_filesystem=YES

# Porta do servidor
listen_port=21
```

---

## 4. Script de Inicialização

### srcs/requirements/bonus/ftp/tools/init.sh

```bash
#!/bin/bash
set -e

# ============================================================================ #
#                        FTP INITIALIZATION SCRIPT                             #
# ============================================================================ #

# Função para ler secrets
read_secret() {
    local secret_file="$1"
    if [ -f "$secret_file" ]; then
        cat "$secret_file" | tr -d '\n'
    else
        echo ""
    fi
}

# Ler credenciais
FTP_PASSWORD=$(read_secret "/run/secrets/ftp_password")

# Usar senha padrão se não definida
if [ -z "$FTP_PASSWORD" ]; then
    FTP_PASSWORD="ftppass123"
    echo "[WARN] Usando senha padrão para FTP"
fi

# Configurar usuário FTP
FTP_USER="${FTP_USER:-ftpuser}"

echo "[INFO] Configurando usuário FTP: $FTP_USER"

# Criar usuário se não existir
if ! id "$FTP_USER" > /dev/null 2>&1; then
    useradd -m -d /var/www/html -s /bin/bash "$FTP_USER"
fi

# Definir senha
echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

# Ajustar permissões
chown -R "$FTP_USER":www-data /var/www/html
chmod -R 775 /var/www/html

# Criar lista de usuários permitidos
echo "$FTP_USER" > /etc/vsftpd.userlist

# Criar diretório de logs
mkdir -p /var/log/vsftpd
touch /var/log/vsftpd/vsftpd.log

# Atualizar pasv_address se DOMAIN_NAME estiver definido
if [ -n "$DOMAIN_NAME" ]; then
    sed -i "s/pasv_address=.*/pasv_address=$DOMAIN_NAME/" /etc/vsftpd.conf
fi

echo "[INFO] Iniciando vsftpd..."

# Usar exec para substituir shell
exec vsftpd /etc/vsftpd.conf
```

---

## 5. Docker Compose

### Adicionar ao docker-compose.yml

```yaml
services:
  # ... serviços existentes ...

  # ========================================================================== #
  #                                    FTP                                     #
  # ========================================================================== #

  ftp:
    build:
      context: ./requirements/bonus/ftp
      dockerfile: Dockerfile
    container_name: ftp
    image: ftp
    restart: unless-stopped
    ports:
      - "21:21"
      - "21100-21110:21100-21110"
    networks:
      - inception
    volumes:
      - wordpress_data:/var/www/html
    environment:
      - FTP_USER=${FTP_USER:-ftpuser}
      - DOMAIN_NAME=${DOMAIN_NAME}
    secrets:
      - ftp_password
    depends_on:
      - wordpress
    healthcheck:
      test: ["CMD", "pgrep", "vsftpd"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

secrets:
  # ... secrets existentes ...
  ftp_password:
    file: ../secrets/ftp_password.txt
```

### Adicionar variáveis ao .env

```env
# FTP
FTP_USER=ftpuser
```

### Criar secret para senha FTP

```bash
echo "SenhaFTPForte789!" > secrets/ftp_password.txt
chmod 600 secrets/ftp_password.txt
```

---

## 6. Testes e Validação

### Iniciar FTP

```bash
# Construir e iniciar
docker compose -f srcs/docker-compose.yml build ftp
docker compose -f srcs/docker-compose.yml up -d ftp

# Ver logs
docker compose -f srcs/docker-compose.yml logs ftp
```

### Testar Conexão FTP

```bash
# Instalar cliente FTP (se não tiver)
sudo apt install ftp

# Conectar
ftp peda-cos.42.fr
# Usuário: ftpuser
# Senha: (do arquivo ftp_password.txt)

# Comandos FTP
ftp> ls
ftp> pwd
ftp> bye
```

### Testar com FileZilla

1. Abra FileZilla
2. Conecte:
   - Host: `peda-cos.42.fr`
   - Port: `21`
   - User: `ftpuser`
   - Password: (do arquivo ftp_password.txt)
3. Verifique se consegue ver os arquivos do WordPress

### Verificar Volume

```bash
# Os arquivos devem ser os mesmos do WordPress
docker compose exec ftp ls -la /var/www/html/
docker compose exec wordpress ls -la /var/www/html/
```

---

## Checklist de Validação

- [ ] Container FTP inicia sem erros
- [ ] Porta 21 acessível
- [ ] Login funciona com usuário/senha
- [ ] Arquivos do WordPress visíveis
- [ ] Upload/download funciona
- [ ] Volume compartilhado com WordPress

---

## Troubleshooting

### Conexão recusada

```bash
# Verificar se vsftpd está rodando
docker compose exec ftp pgrep vsftpd

# Verificar logs
docker compose logs ftp
```

### Modo passivo não funciona

Verifique se as portas 21100-21110 estão expostas e se `pasv_address` está configurado corretamente.

---

## Próxima Etapa

[Ir para 10-BONUS-ADMINER.md](./10-BONUS-ADMINER.md)
