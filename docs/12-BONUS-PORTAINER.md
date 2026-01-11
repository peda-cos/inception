# 12. Bonus: Portainer - Gerenciamento de Containers

[Voltar ao Indice](00-INDICE.md) | [Anterior: Site Estatico](11-BONUS-SITE-ESTATICO.md) | [Proximo: Validacao](13-VALIDACAO-TROUBLESHOOTING.md)

---

## Indice

1. [Introducao](#1-introducao)
2. [O que e o Portainer](#2-o-que-e-o-portainer)
3. [Estrutura de Arquivos](#3-estrutura-de-arquivos)
4. [Dockerfile](#4-dockerfile)
5. [Script de Inicializacao](#5-script-de-inicializacao)
6. [Configuracao NGINX](#6-configuracao-nginx)
7. [Docker Compose](#7-docker-compose)
8. [Primeiro Acesso](#8-primeiro-acesso)
9. [Funcionalidades](#9-funcionalidades)
10. [Seguranca](#10-seguranca)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Introducao

O Portainer e uma interface web para gerenciamento de containers Docker. Com ele, voce pode:

- Visualizar todos os containers, imagens, volumes e redes
- Iniciar, parar, reiniciar containers
- Ver logs em tempo real
- Acessar terminal dos containers
- Gerenciar stacks Docker Compose
- Monitorar recursos (CPU, memoria)

**Importante**: O subject permite "um servico de sua escolha que seja util". O Portainer e extremamente util para debugging e monitoramento durante o desenvolvimento e avaliacao.

---

## 2. O que e o Portainer

### Arquitetura

```
+-------------------+     +------------------+
|    Browser        |     |    Portainer     |
|  (Interface Web)  |<--->|    Container     |
+-------------------+     +--------+---------+
                                   |
                                   v
                          +--------+---------+
                          |   Docker Socket  |
                          |  /var/run/docker |
                          +--------+---------+
                                   |
                    +--------------+---------------+
                    |              |               |
                    v              v               v
              +-----------+ +-----------+ +-------------+
              |  nginx    | | wordpress | |   mariadb   |
              +-----------+ +-----------+ +-------------+
```

### Por que Construir Nossa Propria Imagem?

O subject proibe usar imagens prontas do DockerHub. Precisamos construir o Portainer a partir de uma base Debian, baixando o binario oficial.

---

## 3. Estrutura de Arquivos

```bash
# Criar estrutura do Portainer
mkdir -p srcs/requirements/bonus/portainer/{conf,tools}

# Estrutura final
srcs/requirements/bonus/portainer/
├── Dockerfile
├── conf/
│   └── nginx-portainer.conf
└── tools/
    └── setup.sh
```

---

## 4. Dockerfile

```dockerfile
# srcs/requirements/bonus/portainer/Dockerfile

# ============================================================================
# PORTAINER - Interface de Gerenciamento Docker
# ============================================================================
# Container que fornece interface web para gerenciar Docker.
# Construido sobre Debian Bullseye com binario oficial do Portainer.
# ============================================================================

FROM debian:bullseye

# ----------------------------------------------------------------------------
# Metadados da imagem
# ----------------------------------------------------------------------------
LABEL maintainer="peda-cos@student.42sp.org.br"
LABEL description="Portainer CE for Docker management - 42 Inception"
LABEL version="1.0"

# ----------------------------------------------------------------------------
# Variaveis de build
# ----------------------------------------------------------------------------
# Versao do Portainer Community Edition
ARG PORTAINER_VERSION=2.19.4

# ----------------------------------------------------------------------------
# Instalacao de dependencias
# ----------------------------------------------------------------------------
# curl: para baixar o binario do Portainer
# ca-certificates: para conexoes HTTPS
# procps: necessario para verificacao de PID 1 (ps)
# ----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# Download e instalacao do Portainer
# ----------------------------------------------------------------------------
# O Portainer e distribuido como binario estatico
# Baixamos diretamente do GitHub releases
# ----------------------------------------------------------------------------
RUN curl -L "https://github.com/portainer/portainer/releases/download/${PORTAINER_VERSION}/portainer-${PORTAINER_VERSION}-linux-amd64.tar.gz" \
    -o /tmp/portainer.tar.gz \
    && tar -xzf /tmp/portainer.tar.gz -C /opt \
    && rm /tmp/portainer.tar.gz \
    && chmod +x /opt/portainer/portainer

# ----------------------------------------------------------------------------
# Criar diretorios necessarios
# ----------------------------------------------------------------------------
# /data: onde o Portainer armazena configuracoes e database interno
# ----------------------------------------------------------------------------
RUN mkdir -p /data

# ----------------------------------------------------------------------------
# Copiar script de inicializacao
# ----------------------------------------------------------------------------
COPY tools/setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup.sh

# ----------------------------------------------------------------------------
# Expor porta do Portainer
# ----------------------------------------------------------------------------
# 9000: Interface web HTTP
# 9443: Interface web HTTPS (usaremos proxy via NGINX)
# ----------------------------------------------------------------------------
EXPOSE 9000

# ----------------------------------------------------------------------------
# Healthcheck
# ----------------------------------------------------------------------------
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:9000/api/status || exit 1

# ----------------------------------------------------------------------------
# Ponto de entrada
# ----------------------------------------------------------------------------
ENTRYPOINT ["/usr/local/bin/setup.sh"]
```

---

## 5. Script de Inicializacao

```bash
#!/bin/sh
# srcs/requirements/bonus/portainer/tools/setup.sh

# ============================================================================
# PORTAINER - Script de Inicializacao
# ============================================================================
# Inicializa o Portainer Community Edition
# ============================================================================

set -e

echo "=========================================="
echo "  Portainer - Iniciando..."
echo "=========================================="

# ----------------------------------------------------------------------------
# Verificar binario
# ----------------------------------------------------------------------------
if [ ! -f /opt/portainer/portainer ]; then
    echo "[ERRO] Binario do Portainer nao encontrado!"
    exit 1
fi

echo "[INFO] Portainer binario encontrado"
echo "[INFO] Dados armazenados em: /data"

# ----------------------------------------------------------------------------
# Verificar Docker socket
# ----------------------------------------------------------------------------
if [ -S /var/run/docker.sock ]; then
    echo "[INFO] Docker socket disponivel"
else
    echo "[AVISO] Docker socket nao encontrado - funcionalidade limitada"
fi

# ----------------------------------------------------------------------------
# Iniciar Portainer
# ----------------------------------------------------------------------------
echo "[INFO] Iniciando Portainer na porta 9000..."
echo "=========================================="

# Executar Portainer
# --bind: endereco de escuta
# --data: diretorio de dados
# --no-analytics: desabilitar telemetria
exec /opt/portainer/portainer \
    --bind=":9000" \
    --data=/data \
    --no-analytics
```

---

## 6. Configuracao NGINX

O Portainer sera acessado via subdominio `portainer.peda-cos.42.fr`. Precisamos configurar o NGINX como proxy reverso.

### Adicionar ao NGINX

```nginx
# Adicionar ao srcs/requirements/nginx/conf/nginx.conf
# Ou criar arquivo separado para includes

# ----------------------------------------------------------------------------
# Portainer - Proxy Reverso
# ----------------------------------------------------------------------------
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name portainer.peda-cos.42.fr;

    # Certificados SSL (mesmos do site principal)
    ssl_certificate /etc/nginx/ssl/inception.crt;
    ssl_certificate_key /etc/nginx/ssl/inception.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Logs especificos
    access_log /var/log/nginx/portainer_access.log;
    error_log /var/log/nginx/portainer_error.log;

    # Proxy para Portainer
    location / {
        proxy_pass http://portainer:9000;
        proxy_http_version 1.1;

        # Headers para WebSocket (necessario para terminal)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Headers padrao
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts longos para operacoes demoradas
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket para terminal e logs em tempo real
    location /api/websocket/ {
        proxy_pass http://portainer:9000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 3600s;
    }
}
```

### Atualizar /etc/hosts

```bash
# Adicionar entrada para Portainer
echo "127.0.0.1 portainer.peda-cos.42.fr" | sudo tee -a /etc/hosts
```

---

## 7. Docker Compose

Adicionar ao `srcs/docker-compose.yml`:

```yaml
# ==========================================================================
# PORTAINER - Gerenciamento de Containers (BONUS)
# ==========================================================================
portainer:
  build:
    context: ./requirements/bonus/portainer
    dockerfile: Dockerfile
  container_name: portainer
  restart: unless-stopped

  # ------------------------------------------------------------------------
  # Volumes
  # ------------------------------------------------------------------------
  volumes:
    # Docker socket - OBRIGATORIO para gerenciar containers
    - /var/run/docker.sock:/var/run/docker.sock:ro
    # Dados persistentes do Portainer
    - portainer_data:/data

  # ------------------------------------------------------------------------
  # Rede
  # ------------------------------------------------------------------------
  networks:
    - inception

  # ------------------------------------------------------------------------
  # Dependencias
  # ------------------------------------------------------------------------
  depends_on:
    - nginx

  # ------------------------------------------------------------------------
  # Healthcheck
  # ------------------------------------------------------------------------
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:9000/api/status"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

### Volume Adicional

```yaml
volumes:
  # ... volumes existentes ...

  # Portainer - dados e configuracoes
  portainer_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/peda-cos/data/portainer
```

### Criar Diretorio de Dados

```bash
# Criar diretorio para dados do Portainer
mkdir -p /home/peda-cos/data/portainer
```

---

## 8. Primeiro Acesso

### Acessar o Portainer

1. Iniciar os containers:

   ```bash
   make
   ```

2. Acessar via navegador:

   ```
   https://portainer.peda-cos.42.fr
   ```

3. Aceitar certificado autoassinado

### Configuracao Inicial

No primeiro acesso, voce devera:

1. **Criar usuario administrador**:
   - Username: `admin` (ou outro de sua preferencia)
   - Password: senha forte (minimo 12 caracteres)

2. **Conectar ao Docker local**:
   - Selecionar "Docker" como ambiente
   - Clicar em "Connect"

3. **Pronto!** Voce vera o dashboard com todos os containers

### Tela de Primeiro Acesso

```
+--------------------------------------------------+
|              PORTAINER                           |
|                                                  |
|  Create your initial administrator account       |
|                                                  |
|  Username: [admin________________]               |
|  Password: [********************]                |
|  Confirm:  [********************]                |
|                                                  |
|  [        Create user        ]                   |
|                                                  |
+--------------------------------------------------+
```

---

## 9. Funcionalidades

### Dashboard Principal

```
+------------------------------------------------------------------+
|  PORTAINER          Home | Endpoints | Users | Settings          |
+------------------------------------------------------------------+
|                                                                  |
|  +------------------+  +------------------+  +------------------+|
|  | Containers       |  | Images           |  | Volumes          ||
|  |       6          |  |       8          |  |       4          ||
|  | Running: 6       |  | Size: 1.2GB      |  | In Use: 4        ||
|  +------------------+  +------------------+  +------------------+|
|                                                                  |
|  +------------------+  +------------------+  +------------------+|
|  | Networks         |  | Stacks           |  | Events           ||
|  |       2          |  |       1          |  |       24         ||
|  +------------------+  +------------------+  +------------------+|
|                                                                  |
+------------------------------------------------------------------+
```

### Gerenciamento de Containers

| Acao       | Descricao                        |
| ---------- | -------------------------------- |
| Start/Stop | Iniciar ou parar container       |
| Restart    | Reiniciar container              |
| Kill       | Forcar parada imediata           |
| Remove     | Remover container                |
| Logs       | Ver logs em tempo real           |
| Console    | Terminal interativo no container |
| Inspect    | Ver configuracoes detalhadas     |
| Stats      | Monitorar CPU/Memoria/Rede       |

### Visualizar Logs

1. Clicar no container desejado
2. Clicar em "Logs"
3. Configurar opcoes:
   - Auto-refresh: atualizar automaticamente
   - Timestamps: mostrar data/hora
   - Wrap lines: quebrar linhas longas

### Console do Container

1. Clicar no container
2. Clicar em "Console"
3. Selecionar shell:
   - `/bin/sh` (Alpine/Debian minimal)
   - `/bin/bash` (se disponivel)
4. Clicar em "Connect"

---

## 10. Seguranca

### Boas Praticas

1. **Senha Forte**: Use senha com 12+ caracteres
2. **Acesso Restrito**: Apenas via HTTPS
3. **Docker Socket Read-Only**: Montamos como `:ro`
4. **Sem Porta Exposta**: Acesso apenas via proxy NGINX

### Riscos do Docker Socket

**ATENCAO**: Acesso ao Docker socket equivale a acesso root na maquina host!

```yaml
# Montagem read-only para seguranca
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

Mesmo com `:ro`, ainda e possivel:

- Ver todos os containers
- Ver variaveis de ambiente (possiveis senhas!)
- Ver volumes montados

**Recomendacao**: Em producao, considere:

- Usar Portainer Agent
- Restringir acesso por IP
- Implementar autenticacao adicional

### Restringir Acesso por IP (Opcional)

No NGINX, adicionar:

```nginx
location / {
    # Permitir apenas rede local
    allow 10.0.0.0/8;
    allow 172.16.0.0/12;
    allow 192.168.0.0/16;
    deny all;

    proxy_pass http://portainer:9000;
    # ... resto da configuracao
}
```

---

## 11. Troubleshooting

### Container nao inicia

```bash
# Verificar logs
docker logs portainer

# Verificar se o socket existe
ls -la /var/run/docker.sock

# Verificar permissoes
docker exec portainer ls -la /var/run/docker.sock
```

### Erro "Permission denied" no Docker socket

```bash
# Verificar grupo do socket no host
ls -la /var/run/docker.sock
# srw-rw---- 1 root docker ...

# Se necessario, ajustar no Dockerfile
# (adicionar usuario ao grupo docker)
```

### Nao consegue acessar via HTTPS

```bash
# Verificar se NGINX esta com a configuracao
docker exec nginx nginx -t

# Verificar se Portainer esta respondendo
docker exec nginx curl -s http://portainer:9000/api/status

# Verificar DNS
ping portainer.peda-cos.42.fr
```

### Resetar senha admin

Se esquecer a senha:

```bash
# Parar container
docker stop portainer

# Remover volume de dados (PERDERA CONFIGURACOES!)
docker volume rm inception_portainer_data

# Recriar diretorio
mkdir -p /home/peda-cos/data/portainer

# Reiniciar
docker start portainer
```

### WebSocket nao funciona (terminal)

```bash
# Verificar se proxy WebSocket esta configurado
# O NGINX deve ter:
# proxy_set_header Upgrade $http_upgrade;
# proxy_set_header Connection "upgrade";

# Testar conexao direta
docker exec -it wordpress sh
```

---

## Comandos Uteis

```bash
# Status do Portainer
docker exec portainer curl -s http://localhost:9000/api/status | jq

# Verificar versao
docker exec portainer /opt/portainer/portainer --version

# Logs em tempo real
docker logs -f portainer

# Inspecionar container
docker inspect portainer

# Estatisticas de recursos
docker stats portainer
```

---

## Checklist de Verificacao

- [ ] Dockerfile construido a partir de Debian (nao usa imagem pronta)
- [ ] Binario baixado dos releases oficiais
- [ ] Container inicia sem erros
- [ ] Interface acessivel via HTTPS
- [ ] Usuario admin criado com sucesso
- [ ] Consegue ver todos os containers do projeto
- [ ] Funcao de logs funciona
- [ ] Funcao de terminal funciona
- [ ] Healthcheck passando

---

## Resumo

| Item               | Valor                            |
| ------------------ | -------------------------------- |
| **Servico**        | Portainer CE                     |
| **Porta interna**  | 9000                             |
| **Acesso**         | https://portainer.peda-cos.42.fr |
| **Volume**         | /home/peda-cos/data/portainer    |
| **Dependencia**    | Docker socket                    |
| **Usuario padrao** | Criado no primeiro acesso        |

---

[Voltar ao Indice](00-INDICE.md) | [Anterior: Site Estatico](11-BONUS-SITE-ESTATICO.md) | [Proximo: Validacao](13-VALIDACAO-TROUBLESHOOTING.md)
