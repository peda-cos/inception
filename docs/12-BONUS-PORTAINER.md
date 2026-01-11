# 12. Bonus: Portainer - Gerenciamento de Containers

[Voltar ao Índice](00-INDICE.md) | [Anterior: Site Estático](11-BONUS-SITE-ESTATICO.md) | [Próximo: Validação](13-VALIDACAO-TROUBLESHOOTING.md)

---

## Índice

1. [Introdução](#1-introducao)
2. [O que é o Portainer](#2-o-que-e-o-portainer)
3. [Estrutura de Arquivos](#3-estrutura-de-arquivos)
4. [Dockerfile](#4-dockerfile)
5. [Script de Inicialização](#5-script-de-inicializacao)
6. [Configuração NGINX](#6-configuracao-nginx)
7. [Docker Compose](#7-docker-compose)
8. [Primeiro Acesso](#8-primeiro-acesso)
9. [Funcionalidades](#9-funcionalidades)
10. [Segurança](#10-seguranca)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Introdução

O Portainer é uma interface web para gerenciamento de containers Docker. Com ele, você pode:

- Visualizar todos os containers, imagens, volumes e redes
- Iniciar, parar, reiniciar containers
- Ver logs em tempo real
- Acessar terminal dos containers
- Gerenciar stacks Docker Compose
- Monitorar recursos (CPU, memória)

**Importante**: O subject permite "um serviço de sua escolha que seja útil". O Portainer é extremamente útil para debugging e monitoramento durante o desenvolvimento e avaliação.

---

## 2. O que é o Portainer

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

### Por que Construir Nossa Própria Imagem?

O subject proíbe usar imagens prontas do DockerHub. Precisamos construir o Portainer a partir de uma base Debian, baixando o binário oficial.

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

FROM debian:oldstable

LABEL maintainer="peda-cos@student.42sp.org.br"
LABEL description="Portainer CE for Docker management - 42 Inception"
LABEL version="1.0"

ARG PORTAINER_VERSION=2.21.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L "https://github.com/portainer/portainer/releases/download/${PORTAINER_VERSION}/portainer-${PORTAINER_VERSION}-linux-amd64.tar.gz" \
    -o /tmp/portainer.tar.gz \
    && tar -xzf /tmp/portainer.tar.gz -C /opt \
    && rm /tmp/portainer.tar.gz \
    && chmod +x /opt/portainer/portainer

RUN mkdir -p /data

COPY tools/setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:9000/api/status || exit 1

ENTRYPOINT ["/usr/local/bin/setup.sh"]
```

---

## 5. Script de Inicialização

```bash
#!/bin/sh
# srcs/requirements/bonus/portainer/tools/setup.sh

set -e

echo "=========================================="
echo "  Portainer - Iniciando..."
echo "=========================================="

if [ ! -f /opt/portainer/portainer ]; then
    echo "[ERRO] Binario do Portainer nao encontrado!"
    exit 1
fi

echo "[INFO] Portainer binario encontrado"
echo "[INFO] Dados armazenados em: /data"

if [ -S /var/run/docker.sock ]; then
    echo "[INFO] Docker socket disponivel"
else
    echo "[AVISO] Docker socket nao encontrado - funcionalidade limitada"
fi

echo "[INFO] Iniciando Portainer na porta 9000..."
echo "=========================================="

exec /opt/portainer/portainer \
    --bind=":9000" \
    --data=/data \
    --no-analytics
```

---

## 6. Configuração NGINX

O Portainer será acessado via subdomínio `portainer.peda-cos.42.fr`. Precisamos configurar o NGINX como proxy reverso.

### Adicionar ao NGINX

```nginx
# Adicionar ao srcs/requirements/nginx/conf/nginx.conf

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name portainer.peda-cos.42.fr;

    ssl_certificate /etc/nginx/ssl/inception.crt;
    ssl_certificate_key /etc/nginx/ssl/inception.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    access_log /var/log/nginx/portainer_access.log;
    error_log /var/log/nginx/portainer_error.log;

    location / {
        proxy_pass http://portainer:9000;
        proxy_http_version 1.1;

        # Required for WebSocket (terminal access)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

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
portainer:
  build:
    context: ./requirements/bonus/portainer
    dockerfile: Dockerfile
  container_name: portainer
  restart: unless-stopped
  volumes:
    # Read-only access to Docker socket for security
    - /var/run/docker.sock:/var/run/docker.sock:ro
    - portainer_data:/data
  networks:
    - inception
  depends_on:
    - nginx
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

  portainer_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/peda-cos/data/portainer
```

### Criar Diretório de Dados

```bash
# Criar diretório para dados do Portainer
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

### Configuração Inicial

No primeiro acesso, você deverá:

1. **Criar usuário administrador**:
   - Username: `admin` (ou outro de sua preferência)
   - Password: senha forte (mínimo 12 caracteres)

2. **Conectar ao Docker local**:
   - Selecionar "Docker" como ambiente
   - Clicar em "Connect"

3. **Pronto!** Você verá o dashboard com todos os containers

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

| Ação       | Descrição                        |
| ---------- | -------------------------------- |
| Start/Stop | Iniciar ou parar container       |
| Restart    | Reiniciar container              |
| Kill       | Forçar parada imediata           |
| Remove     | Remover container                |
| Logs       | Ver logs em tempo real           |
| Console    | Terminal interativo no container |
| Inspect    | Ver configurações detalhadas     |
| Stats      | Monitorar CPU/Memória/Rede       |

### Visualizar Logs

1. Clicar no container desejado
2. Clicar em "Logs"
3. Configurar opções:
   - Auto-refresh: atualizar automaticamente
   - Timestamps: mostrar data/hora
   - Wrap lines: quebrar linhas longas

### Console do Container

1. Clicar no container
2. Clicar em "Console"
3. Selecionar shell:
   - `/bin/sh` (Alpine/Debian minimal)
   - `/bin/bash` (se disponível)
4. Clicar em "Connect"

---

## 10. Segurança

### Boas Práticas

1. **Senha Forte**: Use senha com 12+ caracteres
2. **Acesso Restrito**: Apenas via HTTPS
3. **Docker Socket Read-Only**: Montamos como `:ro`
4. **Sem Porta Exposta**: Acesso apenas via proxy NGINX

### Riscos do Docker Socket

**ATENÇÃO**: Acesso ao Docker socket equivale a acesso root na máquina host!

```yaml
# Montagem read-only para segurança
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

Mesmo com `:ro`, ainda é possível:

- Ver todos os containers
- Ver variáveis de ambiente (possíveis senhas!)
- Ver volumes montados

**Recomendação**: Em produção, considere:

- Usar Portainer Agent
- Restringir acesso por IP
- Implementar autenticação adicional

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
    # ... resto da configuração
}
```

---

## 11. Troubleshooting

### Container não inicia

```bash
# Verificar logs
docker logs portainer

# Verificar se o socket existe
ls -la /var/run/docker.sock

# Verificar permissões
docker exec portainer ls -la /var/run/docker.sock
```

### Erro "Permission denied" no Docker socket

```bash
# Verificar grupo do socket no host
ls -la /var/run/docker.sock
# srw-rw---- 1 root docker ...

# Se necessário, ajustar no Dockerfile
# (adicionar usuário ao grupo docker)
```

### Não consegue acessar via HTTPS

```bash
# Verificar se NGINX está com a configuração
docker exec nginx nginx -t

# Verificar se Portainer está respondendo
docker exec nginx curl -s http://portainer:9000/api/status

# Verificar DNS
ping portainer.peda-cos.42.fr
```

### Resetar senha admin

Se esquecer a senha:

```bash
# Parar container
docker stop portainer

# Remover volume de dados (PERDERÁ CONFIGURAÇÕES!)
docker volume rm inception_portainer_data

# Recriar diretório
mkdir -p /home/peda-cos/data/portainer

# Reiniciar
docker start portainer
```

### WebSocket não funciona (terminal)

```bash
# Verificar se proxy WebSocket está configurado
# O NGINX deve ter:
# proxy_set_header Upgrade $http_upgrade;
# proxy_set_header Connection "upgrade";

# Testar conexão direta
docker exec -it wordpress sh
```

---

## Comandos Úteis

```bash
# Status do Portainer
docker exec portainer curl -s http://localhost:9000/api/status | jq

# Verificar versão
docker exec portainer /opt/portainer/portainer --version

# Logs em tempo real
docker logs -f portainer

# Inspecionar container
docker inspect portainer

# Estatísticas de recursos
docker stats portainer
```

---

## Checklist de Verificação

- [ ] Dockerfile construído a partir de Debian (não usa imagem pronta)
- [ ] Binário baixado dos releases oficiais
- [ ] Container inicia sem erros
- [ ] Interface acessível via HTTPS
- [ ] Usuário admin criado com sucesso
- [ ] Consegue ver todos os containers do projeto
- [ ] Função de logs funciona
- [ ] Função de terminal funciona
- [ ] Healthcheck passando

---

## Resumo

| Item               | Valor                            |
| ------------------ | -------------------------------- |
| **Serviço**        | Portainer CE                     |
| **Porta interna**  | 9000                             |
| **Acesso**         | https://portainer.peda-cos.42.fr |
| **Volume**         | /home/peda-cos/data/portainer    |
| **Dependência**    | Docker socket                    |
| **Usuário padrão** | Criado no primeiro acesso        |

---

[Voltar ao Índice](00-INDICE.md) | [Anterior: Site Estático](11-BONUS-SITE-ESTATICO.md) | [Próximo: Validação](13-VALIDACAO-TROUBLESHOOTING.md)
