# 08 - Bônus: Redis Cache

[Voltar ao Índice](./00-INDICE.md) | [Anterior: Docker Compose](./07-DOCKER-COMPOSE.md)

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Dockerfile](#2-dockerfile)
3. [Configuração Redis](#3-configuração-redis)
4. [Integração com WordPress](#4-integração-com-wordpress)
5. [Docker Compose](#5-docker-compose)
6. [Testes e Validação](#6-testes-e-validação)

---

## 1. Visão Geral

Redis é um banco de dados em memória usado para cache. No WordPress:

- **Object Cache**: Armazena consultas de banco de dados em memória
- **Reduz carga no MariaDB**: Consultas repetidas são servidas do cache
- **Melhora performance**: Páginas carregam mais rápido

### Arquitetura

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   NGINX      │ ──► │  WORDPRESS   │ ──► │   MARIADB    │
│              │     │   + PHP-FPM  │     │              │
└──────────────┘     └──────┬───────┘     └──────────────┘
                           │
                           │ Object Cache
                           ▼
                    ┌──────────────┐
                    │    REDIS     │
                    │   (cache)    │
                    └──────────────┘
```

### Arquivos a Criar

```
srcs/requirements/bonus/redis/
├── Dockerfile
├── .dockerignore
├── conf/
│   └── redis.conf
└── tools/
    └── init.sh
```

---

## 2. Dockerfile

### srcs/requirements/bonus/redis/Dockerfile

```dockerfile
FROM debian:oldstable

RUN apt-get update && apt-get install -y --no-install-recommends \
    redis-server \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/redis \
    && mkdir -p /var/lib/redis \
    && chown -R redis:redis /var/run/redis \
    && chown -R redis:redis /var/lib/redis

COPY conf/redis.conf /etc/redis/redis.conf

COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 6379

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD redis-cli ping | grep -q PONG || exit 1

ENTRYPOINT ["/usr/local/bin/init.sh"]
```

---

## 3. Configuração Redis

### srcs/requirements/bonus/redis/conf/redis.conf

```conf
bind 0.0.0.0
port 6379

# Disabled because we're inside an isolated Docker network
protected-mode no

timeout 0
tcp-keepalive 300

# Docker requires foreground process
daemonize no

loglevel notice

# Empty string = log to stdout for Docker logs
logfile ""

databases 16

# Persistence disabled for pure cache; uncomment to enable
# save 900 1
# save 300 10
# save 60 10000

dir /var/lib/redis

maxmemory 128mb
maxmemory-policy allkeys-lru

save ""
appendonly no
```

### srcs/requirements/bonus/redis/tools/init.sh

```bash
#!/bin/sh
set -e

echo "[INFO] Iniciando Redis..."

chown -R redis:redis /var/lib/redis
chown -R redis:redis /var/run/redis

exec redis-server /etc/redis/redis.conf
```

---

## 4. Integração com WordPress

### 4.1 Configurar variáveis de ambiente

Adicione ao `srcs/.env`:

```env
# Redis
REDIS_HOST=redis
REDIS_PORT=6379
```

### 4.2 Atualizar script do WordPress

O script `init.sh` do WordPress já tem suporte a Redis. Verifique:

```bash
# Configuração para Redis (bônus)
if [ -n "$REDIS_HOST" ]; then
    wp config set WP_REDIS_HOST "$REDIS_HOST" --allow-root
    wp config set WP_REDIS_PORT "${REDIS_PORT:-6379}" --allow-root
    wp config set WP_CACHE true --raw --allow-root
fi
```

### 4.3 Instalar plugin Redis Object Cache

Adicione ao script do WordPress após instalação:

```bash
# Instalar e ativar Redis Object Cache (se Redis configurado)
if [ -n "$REDIS_HOST" ]; then
    echo "[INFO] Configurando Redis Object Cache..."
    wp plugin install redis-cache --activate --allow-root || true
    wp redis enable --allow-root || true
fi
```

---

## 5. Docker Compose

### Adicionar ao docker-compose.yml

```yaml
services:
  # ... serviços existentes ...

  redis:
    build:
      context: ./requirements/bonus/redis
      dockerfile: Dockerfile
    container_name: redis
    image: redis
    restart: unless-stopped
    networks:
      - inception
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s
```

### Atualizar serviço WordPress

Adicione dependência do Redis (opcional):

```yaml
wordpress:
  # ... configuração existente ...
  environment:
    # ... variáveis existentes ...
    - REDIS_HOST=${REDIS_HOST:-}
    - REDIS_PORT=${REDIS_PORT:-}
  depends_on:
    mariadb:
      condition: service_healthy
    redis:
      condition: service_healthy
```

---

## 6. Testes e Validação

### Iniciar Redis

```bash
# Construir e iniciar
docker compose -f srcs/docker-compose.yml build redis
docker compose -f srcs/docker-compose.yml up -d redis

# Ver logs
docker compose -f srcs/docker-compose.yml logs redis
```

### Verificar Redis

```bash
# Testar ping
docker compose exec redis redis-cli ping
# Esperado: PONG

# Ver informações
docker compose exec redis redis-cli info

# Verificar memória
docker compose exec redis redis-cli info memory | grep used_memory_human
```

### Verificar Integração com WordPress

```bash
# Acessar WordPress
docker compose exec wordpress bash

# Verificar status do Redis
wp redis status --allow-root

# Ver se cache está funcionando
wp redis info --allow-root

# Sair
exit
```

### Testar Cache

1. Acesse o painel admin do WordPress: `https://peda-cos.42.fr/wp-admin`
2. Vá em **Plugins** > **Redis Object Cache**
3. Verifique se mostra "Connected"
4. Use "Flush Cache" para limpar cache

---

## Checklist de Validação

- [ ] Container Redis inicia sem erros
- [ ] Redis responde ao PING
- [ ] WordPress conecta ao Redis
- [ ] Plugin Redis Object Cache ativo
- [ ] Cache funcionando (verificar via wp-admin)

---

## Troubleshooting

### Redis não conecta

```bash
# Verificar se está escutando
docker compose exec redis netstat -tlnp | grep 6379

# Testar conexão do WordPress
docker compose exec wordpress redis-cli -h redis ping
```

### Plugin não ativa

```bash
# Instalar manualmente
docker compose exec wordpress wp plugin install redis-cache --activate --allow-root

# Habilitar cache
docker compose exec wordpress wp redis enable --allow-root
```

---

## Próxima Etapa

[Ir para 09-BONUS-FTP.md](./09-BONUS-FTP.md)
