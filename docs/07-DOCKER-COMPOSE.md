# 07 - Docker Compose (Orquestração Completa)

[Voltar ao Índice](./00-INDICE.md) | [Anterior: NGINX](./06-NGINX.md)

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [docker-compose.yml Completo](#2-docker-composeyml-completo)
3. [Explicação Detalhada](#3-explicação-detalhada)
4. [Ordem de Inicialização](#4-ordem-de-inicialização)
5. [Comandos de Gerenciamento](#5-comandos-de-gerenciamento)
6. [Validação Final](#6-validação-final)

---

## 1. Visão Geral

O Docker Compose orquestra todos os serviços do Inception:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              HOST (VM)                                       │
│                                                                              │
│    ┌─────────────────────────────────────────────────────────────────────┐  │
│    │                      DOCKER NETWORK (inception)                      │  │
│    │                                                                      │  │
│    │   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐         │  │
│    │   │    NGINX     │    │  WORDPRESS   │    │   MARIADB    │         │  │
│    │   │              │    │   + PHP-FPM  │    │              │         │  │
│    │   │  Port 443    │───►│   Port 9000  │───►│  Port 3306   │         │  │
│    │   │  (exposed)   │    │  (internal)  │    │  (internal)  │         │  │
│    │   └──────┬───────┘    └──────┬───────┘    └──────┬───────┘         │  │
│    │          │                   │                   │                  │  │
│    └──────────┼───────────────────┼───────────────────┼──────────────────┘  │
│               │                   │                   │                     │
│    ┌──────────▼───────────────────▼───────────────────▼──────────────────┐  │
│    │                           VOLUMES                                    │  │
│    │   /home/peda-cos/data/wordpress    /home/peda-cos/data/mariadb      │  │
│    └─────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Requisitos do Subject

- [ ] Usar docker-compose
- [ ] Cada serviço em container dedicado
- [ ] Rede Docker customizada (não usar host ou --link)
- [ ] Volumes persistentes em `/home/peda-cos/data/`
- [ ] Containers reiniciam em caso de crash
- [ ] Secrets para senhas sensíveis
- [ ] Apenas porta 443 exposta

---

## 2. docker-compose.yml Completo

### srcs/docker-compose.yml

```yaml
# ============================================================================ #
#                        INCEPTION - DOCKER COMPOSE                            #
#                                                                              #
#  Autor: peda-cos                                                             #
#  42sp - São Paulo                                                            #
# ============================================================================ #

version: "3.8"

# ============================================================================ #
#                                  SERVIÇOS                                    #
# ============================================================================ #

services:
  # ========================================================================== #
  #                                  MARIADB                                   #
  # ========================================================================== #

  mariadb:
    build:
      context: ./requirements/mariadb
      dockerfile: Dockerfile
    container_name: mariadb
    image: mariadb
    restart: unless-stopped
    networks:
      - inception
    volumes:
      - db_data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/db_root_password
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password
      - db_root_password
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "--silent"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  # ========================================================================== #
  #                               WORDPRESS                                    #
  # ========================================================================== #

  wordpress:
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    container_name: wordpress
    image: wordpress
    restart: unless-stopped
    networks:
      - inception
    volumes:
      - wordpress_data:/var/www/html
    environment:
      - DOMAIN_NAME=${DOMAIN_NAME}
      - WORDPRESS_DB_HOST=${WORDPRESS_DB_HOST}
      - WORDPRESS_DB_NAME=${WORDPRESS_DB_NAME}
      - WORDPRESS_DB_USER=${WORDPRESS_DB_USER}
      - WORDPRESS_DB_PASSWORD_FILE=/run/secrets/db_password
      - WORDPRESS_TITLE=${WORDPRESS_TITLE}
      - WORDPRESS_ADMIN_USER=${WORDPRESS_ADMIN_USER}
      - WORDPRESS_ADMIN_EMAIL=${WORDPRESS_ADMIN_EMAIL}
      - WORDPRESS_USER=${WORDPRESS_USER}
      - WORDPRESS_USER_EMAIL=${WORDPRESS_USER_EMAIL}
      - WORDPRESS_USER_ROLE=${WORDPRESS_USER_ROLE}
      # Redis cache (bonus)
      - REDIS_HOST=${REDIS_HOST:-}
      - REDIS_PORT=${REDIS_PORT:-}
    secrets:
      - db_password
      - credentials
    depends_on:
      mariadb:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "pgrep", "php-fpm"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 60s

  # ========================================================================== #
  #                                  NGINX                                     #
  # ========================================================================== #

  nginx:
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    container_name: nginx
    image: nginx
    restart: unless-stopped
    ports:
      - "443:443"
    networks:
      - inception
    volumes:
      - wordpress_data:/var/www/html:ro
    environment:
      - DOMAIN_NAME=${DOMAIN_NAME}
    depends_on:
      wordpress:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-fsk", "https://localhost/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s

# ============================================================================ #
#                                   REDES                                      #
# ============================================================================ #

networks:
  inception:
    name: inception
    driver: bridge

# ============================================================================ #
#                                  VOLUMES                                     #
# ============================================================================ #

volumes:
  # Volume para dados do WordPress
  wordpress_data:
    name: wordpress_data
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/peda-cos/data/wordpress

  # Volume para dados do MariaDB
  db_data:
    name: db_data
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/peda-cos/data/mariadb

# ============================================================================ #
#                                  SECRETS                                     #
# ============================================================================ #

secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt
  credentials:
    file: ../secrets/credentials.txt
```

---

## 3. Explicação Detalhada

### 3.1 Versão

```yaml
version: "3.8"
```

Usar versão 3.8 para recursos modernos como `condition: service_healthy`.

### 3.2 Serviços

#### MariaDB

| Configuração              | Propósito                 |
| ------------------------- | ------------------------- |
| `restart: unless-stopped` | Reinicia em caso de crash |
| `networks: - inception`   | Rede isolada              |
| `volumes: db_data`        | Persistência de dados     |
| `secrets`                 | Senhas seguras            |
| `healthcheck`             | Verificação de saúde      |

#### WordPress

| Configuração                                      | Propósito             |
| ------------------------------------------------- | --------------------- |
| `depends_on: mariadb: condition: service_healthy` | Aguarda MariaDB       |
| `volumes: wordpress_data`                         | Arquivos persistentes |
| `WORDPRESS_DB_PASSWORD_FILE`                      | Senha via secret      |

#### NGINX

| Configuração                               | Propósito               |
| ------------------------------------------ | ----------------------- |
| `ports: - "443:443"`                       | **ÚNICA** porta exposta |
| `volumes: wordpress_data:/var/www/html:ro` | Read-only para arquivos |
| `depends_on: wordpress`                    | Aguarda WordPress       |

### 3.3 Redes

```yaml
networks:
  inception:
    name: inception
    driver: bridge
```

- **bridge**: Rede isolada entre containers
- Containers se comunicam por nome (`mariadb`, `wordpress`)
- **NÃO** usar `network: host` (proibido pelo subject)
- **NÃO** usar `--link` (deprecated e proibido)

### 3.4 Volumes

```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/peda-cos/data/wordpress
```

Esta configuração cria um **volume nomeado** que aponta para um diretório específico no host, conforme exigido pelo subject.

| Configuração                      | Propósito                       |
| --------------------------------- | ------------------------------- |
| `driver: local`                   | Driver local do Docker          |
| `type: none`                      | Sem tipo de filesystem especial |
| `o: bind`                         | Bind mount para o diretório     |
| `device: /home/peda-cos/data/...` | Caminho no host                 |

### 3.5 Secrets

```yaml
secrets:
  db_password:
    file: ../secrets/db_password.txt
```

- Secrets são montados em `/run/secrets/` dentro do container
- Mais seguros que variáveis de ambiente
- Não aparecem em `docker inspect`

---

## 4. Ordem de Inicialização

```
1. MariaDB inicia
      │
      ▼
2. MariaDB health check passa
      │
      ▼
3. WordPress inicia
      │
      ▼
4. WordPress aguarda MariaDB (no script)
      │
      ▼
5. WordPress configura banco de dados
      │
      ▼
6. WordPress health check passa
      │
      ▼
7. NGINX inicia
      │
      ▼
8. NGINX health check passa
      │
      ▼
9. Sistema pronto! ✓
```

O `depends_on` com `condition: service_healthy` garante a ordem correta:

```yaml
depends_on:
  mariadb:
    condition: service_healthy
```

---

## 5. Comandos de Gerenciamento

### Inicialização

```bash
# Criar diretórios de dados (se não existirem)
mkdir -p /home/peda-cos/data/{wordpress,mariadb}

# Construir imagens
docker compose -f srcs/docker-compose.yml build

# Iniciar todos os serviços
docker compose -f srcs/docker-compose.yml up -d

# Ou via Makefile
make
```

### Monitoramento

```bash
# Ver status
docker compose -f srcs/docker-compose.yml ps

# Ver logs de todos os serviços
docker compose -f srcs/docker-compose.yml logs -f

# Ver logs de um serviço específico
docker compose -f srcs/docker-compose.yml logs -f nginx

# Ver uso de recursos
docker stats
```

### Manutenção

```bash
# Parar serviços
docker compose -f srcs/docker-compose.yml down

# Reconstruir um serviço
docker compose -f srcs/docker-compose.yml build nginx
docker compose -f srcs/docker-compose.yml up -d nginx

# Reiniciar um serviço
docker compose -f srcs/docker-compose.yml restart wordpress

# Acessar shell de um container
docker compose -f srcs/docker-compose.yml exec nginx sh
docker compose -f srcs/docker-compose.yml exec wordpress bash
docker compose -f srcs/docker-compose.yml exec mariadb bash
```

### Limpeza

```bash
# Parar e remover containers
docker compose -f srcs/docker-compose.yml down

# Parar, remover containers e volumes
docker compose -f srcs/docker-compose.yml down -v

# Remover também imagens
docker compose -f srcs/docker-compose.yml down --rmi all -v

# Limpeza completa
make fclean
```

---

## 6. Validação Final

### Script de Validação Completa

Crie um script para validar toda a instalação:

```bash
#!/bin/bash

# ============================================================================ #
#                         INCEPTION VALIDATION SCRIPT                          #
# ============================================================================ #

echo "=========================================="
echo "   INCEPTION - VALIDAÇÃO COMPLETA"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

ERRORS=0

# Função de teste
check() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}[PASS]${NC} $2"
    else
        echo -e "${RED}[FAIL]${NC} $2"
        ERRORS=$((ERRORS + 1))
    fi
}

# 1. Verificar containers rodando
echo -e "\n${YELLOW}1. Containers${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "mariadb|wordpress|nginx"
check $(docker ps | grep -c "healthy") "Todos os containers saudáveis (3 esperados)"

# 2. Verificar porta 443
echo -e "\n${YELLOW}2. Porta 443${NC}"
curl -sk https://peda-cos.42.fr/health > /dev/null 2>&1
check $? "HTTPS acessível na porta 443"

# 3. Verificar TLSv1.2
echo -e "\n${YELLOW}3. TLS${NC}"
openssl s_client -connect peda-cos.42.fr:443 -tls1_2 < /dev/null 2>&1 | grep -q "Protocol.*TLSv1.2"
check $? "TLSv1.2 suportado"

# 4. Verificar TLSv1.3
openssl s_client -connect peda-cos.42.fr:443 -tls1_3 < /dev/null 2>&1 | grep -q "Protocol.*TLSv1.3"
check $? "TLSv1.3 suportado"

# 5. Verificar que TLSv1.1 é rejeitado
openssl s_client -connect peda-cos.42.fr:443 -tls1_1 < /dev/null 2>&1 | grep -q "handshake failure\|no protocols available"
check $? "TLSv1.1 rejeitado"

# 6. Verificar WordPress
echo -e "\n${YELLOW}4. WordPress${NC}"
curl -sk https://peda-cos.42.fr/ | grep -q "WordPress\|wp-content"
check $? "WordPress respondendo"

# 7. Verificar volumes
echo -e "\n${YELLOW}5. Volumes${NC}"
ls /home/peda-cos/data/wordpress/wp-config.php > /dev/null 2>&1
check $? "Volume WordPress persistido"

ls /home/peda-cos/data/mariadb/ibdata1 > /dev/null 2>&1
check $? "Volume MariaDB persistido"

# 8. Verificar rede
echo -e "\n${YELLOW}6. Rede${NC}"
docker network ls | grep -q "inception"
check $? "Rede 'inception' existe"

# 9. Verificar que apenas porta 443 está exposta
echo -e "\n${YELLOW}7. Portas expostas${NC}"
EXPOSED=$(docker ps --format "{{.Ports}}" | grep -oE "[0-9]+:[0-9]+" | cut -d: -f1 | sort -u | tr '\n' ' ')
if [ "$EXPOSED" = "443 " ] || [ "$EXPOSED" = "443" ]; then
    check 0 "Apenas porta 443 exposta ($EXPOSED)"
else
    check 1 "Apenas porta 443 exposta (encontradas: $EXPOSED)"
fi

# 10. Verificar usuários WordPress
echo -e "\n${YELLOW}8. Usuários WordPress${NC}"
ADMIN_USER=$(docker exec wordpress wp user list --role=administrator --field=user_login --allow-root 2>/dev/null | head -1)
if echo "$ADMIN_USER" | grep -iqE "admin|administrator"; then
    check 1 "Admin não contém 'admin' (encontrado: $ADMIN_USER)"
else
    check 0 "Admin não contém 'admin' (usuário: $ADMIN_USER)"
fi

USER_COUNT=$(docker exec wordpress wp user list --allow-root 2>/dev/null | wc -l)
if [ "$USER_COUNT" -ge 2 ]; then
    check 0 "Pelo menos 2 usuários criados ($((USER_COUNT - 1)) usuários)"
else
    check 1 "Pelo menos 2 usuários criados"
fi

# 11. Verificar restart policy
echo -e "\n${YELLOW}9. Restart Policy${NC}"
for container in nginx wordpress mariadb; do
    RESTART=$(docker inspect --format '{{.HostConfig.RestartPolicy.Name}}' $container 2>/dev/null)
    if [ "$RESTART" = "unless-stopped" ] || [ "$RESTART" = "always" ]; then
        check 0 "$container restart policy: $RESTART"
    else
        check 1 "$container restart policy: $RESTART (esperado: unless-stopped)"
    fi
done

# Resumo
echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "   ${GREEN}TODOS OS TESTES PASSARAM!${NC}"
else
    echo -e "   ${RED}$ERRORS TESTE(S) FALHARAM${NC}"
fi
echo "=========================================="

exit $ERRORS
```

Salve como `validate.sh` e execute:

```bash
chmod +x validate.sh
./validate.sh
```

### Resultado Esperado

```
==========================================
   INCEPTION - VALIDAÇÃO COMPLETA
==========================================

1. Containers
NAMES       STATUS
nginx       Up 5 minutes (healthy)
wordpress   Up 5 minutes (healthy)
mariadb     Up 5 minutes (healthy)
[PASS] Todos os containers saudáveis (3 esperados)

2. Porta 443
[PASS] HTTPS acessível na porta 443

3. TLS
[PASS] TLSv1.2 suportado
[PASS] TLSv1.3 suportado
[PASS] TLSv1.1 rejeitado

4. WordPress
[PASS] WordPress respondendo

5. Volumes
[PASS] Volume WordPress persistido
[PASS] Volume MariaDB persistido

6. Rede
[PASS] Rede 'inception' existe

7. Portas expostas
[PASS] Apenas porta 443 exposta (443)

8. Usuários WordPress
[PASS] Admin não contém 'admin' (usuário: supervisor)
[PASS] Pelo menos 2 usuários criados (2 usuários)

9. Restart Policy
[PASS] nginx restart policy: unless-stopped
[PASS] wordpress restart policy: unless-stopped
[PASS] mariadb restart policy: unless-stopped

==========================================
   TODOS OS TESTES PASSARAM!
==========================================
```

---

## Checklist Final da Parte Obrigatória

- [ ] Todos os containers iniciando corretamente
- [ ] MariaDB healthy e persistindo dados
- [ ] WordPress instalado e configurado
- [ ] Dois usuários WordPress (admin sem "admin" no nome)
- [ ] NGINX servindo via HTTPS apenas
- [ ] TLSv1.2 e TLSv1.3 funcionando
- [ ] TLSv1.0 e TLSv1.1 rejeitados
- [ ] Apenas porta 443 exposta
- [ ] Volumes persistindo em `/home/peda-cos/data/`
- [ ] Rede Docker customizada (inception)
- [ ] Restart policy configurada
- [ ] Secrets sendo usados para senhas
- [ ] Site acessível em `https://peda-cos.42.fr`

---

## Próxima Etapa

Com a parte obrigatória concluída, vamos para os bônus:

[Ir para 08-BONUS-REDIS.md](./08-BONUS-REDIS.md)
