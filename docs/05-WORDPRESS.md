# 05 - WordPress + PHP-FPM

[Voltar ao Índice](./00-INDICE.md) | [Anterior: MariaDB](./04-MARIADB.md)

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Dockerfile](#2-dockerfile)
3. [Script de Inicialização](#3-script-de-inicialização)
4. [Configuração PHP-FPM](#4-configuração-php-fpm)
5. [Integração com Docker Compose](#5-integração-com-docker-compose)
6. [Testes e Validação](#6-testes-e-validação)

---

## 1. Visão Geral

O container WordPress é responsável por:

- Executar o WordPress com PHP-FPM
- Conectar-se ao MariaDB para persistência
- Servir conteúdo via FastCGI para o NGINX
- Gerenciar arquivos do site em volume externo

### Requisitos do Subject

- WordPress + php-fpm **SEM nginx** no container
- Dois usuários WordPress (admin sem "admin" no nome)
- Dados persistidos em `/home/peda-cos/data/wordpress`
- Conexão com MariaDB via rede Docker
- Reiniciar automaticamente em caso de crash

### Arquivos a Criar

```
srcs/requirements/wordpress/
├── Dockerfile
├── .dockerignore
├── conf/
│   └── www.conf
└── tools/
    └── init.sh
```

---

## 2. Dockerfile

### srcs/requirements/wordpress/Dockerfile

```dockerfile
FROM debian:oldstable

RUN apt-get update && apt-get install -y --no-install-recommends \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-intl \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    php8.2-bcmath \
    php8.2-imagick \
    php8.2-redis \
    curl \
    mariadb-client \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

RUN mkdir -p /run/php \
    && chown -R www-data:www-data /run/php

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

WORKDIR /var/www/html

EXPOSE 9000

HEALTHCHECK --interval=10s --timeout=5s --start-period=60s --retries=5 \
    CMD pgrep php-fpm > /dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/init.sh"]
```

### Explicação das Instruções

| Instrução              | Propósito                                |
| ---------------------- | ---------------------------------------- |
| `php8.2-fpm`           | FastCGI Process Manager para PHP         |
| `php8.2-mysql`         | Extensão para conexão com MySQL/MariaDB  |
| `php8.2-gd`, `imagick` | Manipulação de imagens                   |
| `php8.2-redis`         | Suporte a Redis (para bônus)             |
| `procps`               | Para comandos ps/pgrep (verificar PID 1) |
| `wp-cli.phar`          | Ferramenta CLI para gerenciar WordPress  |
| `EXPOSE 9000`          | Porta padrão do PHP-FPM                  |

---

## 3. Script de Inicialização

Este script configura o WordPress na primeira execução.

### srcs/requirements/wordpress/tools/init.sh

```bash
#!/bin/bash
set -e

read_secret() {
    local secret_file="$1"
    if [ -f "$secret_file" ]; then
        cat "$secret_file" | tr -d '\n'
    else
        echo ""
    fi
}

read_credentials() {
    local cred_file="/run/secrets/credentials"
    if [ -f "$cred_file" ]; then
        grep "^$1=" "$cred_file" | cut -d'=' -f2 | tr -d '\n'
    else
        echo ""
    fi
}

DB_PASSWORD=$(read_secret "${WORDPRESS_DB_PASSWORD_FILE}")
ADMIN_PASSWORD=$(read_credentials "WORDPRESS_ADMIN_PASSWORD")
USER_PASSWORD=$(read_credentials "WORDPRESS_USER_PASSWORD")

if [ -z "$ADMIN_PASSWORD" ]; then
    ADMIN_PASSWORD="ChangeMe123!"
fi

if [ -z "$USER_PASSWORD" ]; then
    USER_PASSWORD="ChangeMe456!"
fi

if [ -z "$WORDPRESS_DB_HOST" ]; then
    echo "[ERROR] WORDPRESS_DB_HOST não definido"
    exit 1
fi

if [ -z "$WORDPRESS_DB_NAME" ]; then
    echo "[ERROR] WORDPRESS_DB_NAME não definido"
    exit 1
fi

if [ -z "$WORDPRESS_DB_USER" ]; then
    echo "[ERROR] WORDPRESS_DB_USER não definido"
    exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
    echo "[ERROR] DB_PASSWORD não definido"
    exit 1
fi

if [ -z "$DOMAIN_NAME" ]; then
    echo "[ERROR] DOMAIN_NAME não definido"
    exit 1
fi

# Subject requirement: admin username must not contain "admin"
if echo "$WORDPRESS_ADMIN_USER" | grep -iq "admin"; then
    echo "[ERROR] Nome do administrador não pode conter 'admin'"
    exit 1
fi

DB_HOST=$(echo "$WORDPRESS_DB_HOST" | cut -d':' -f1)
DB_PORT=$(echo "$WORDPRESS_DB_HOST" | cut -d':' -f2)
DB_PORT=${DB_PORT:-3306}

echo "[INFO] Aguardando MariaDB em $DB_HOST:$DB_PORT..."
max_attempts=60
attempt=0
while ! mysqladmin ping -h "$DB_HOST" -P "$DB_PORT" --silent 2>/dev/null; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "[ERROR] MariaDB não respondeu após $max_attempts tentativas"
        exit 1
    fi
    echo "[INFO] Tentativa $attempt/$max_attempts..."
    sleep 2
done
echo "[INFO] MariaDB está pronto!"

cd /var/www/html

if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "[INFO] Primeira inicialização - Configurando WordPress..."

    if [ ! -f "/var/www/html/wp-load.php" ]; then
        echo "[INFO] Baixando WordPress..."
        wp core download --allow-root --locale=pt_BR
    fi

    echo "[INFO] Criando wp-config.php..."
    wp config create \
        --dbname="$WORDPRESS_DB_NAME" \
        --dbuser="$WORDPRESS_DB_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost="$DB_HOST:$DB_PORT" \
        --dbcharset="utf8mb4" \
        --dbcollate="utf8mb4_unicode_ci" \
        --allow-root

    wp config set WP_DEBUG false --raw --allow-root
    wp config set WP_DEBUG_LOG false --raw --allow-root
    wp config set WP_DEBUG_DISPLAY false --raw --allow-root
    wp config set DISALLOW_FILE_EDIT true --raw --allow-root

    if [ -n "$REDIS_HOST" ]; then
        wp config set WP_REDIS_HOST "$REDIS_HOST" --allow-root
        wp config set WP_REDIS_PORT "${REDIS_PORT:-6379}" --allow-root
        wp config set WP_CACHE true --raw --allow-root
    fi

    echo "[INFO] Instalando WordPress..."
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WORDPRESS_TITLE:-Inception}" \
        --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$ADMIN_PASSWORD" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    echo "[INFO] Criando segundo usuário..."
    wp user create \
        "$WORDPRESS_USER" \
        "$WORDPRESS_USER_EMAIL" \
        --role="${WORDPRESS_USER_ROLE:-editor}" \
        --user_pass="$USER_PASSWORD" \
        --allow-root || echo "[WARN] Usuário já existe"

    wp rewrite structure '/%postname%/' --allow-root
    wp rewrite flush --allow-root

    wp theme activate twentytwentythree --allow-root 2>/dev/null || true

    wp language core update --allow-root 2>/dev/null || true

    echo "[INFO] WordPress instalado com sucesso!"
    echo "[INFO] - URL: https://${DOMAIN_NAME}"
    echo "[INFO] - Admin: $WORDPRESS_ADMIN_USER"
    echo "[INFO] - Usuário: $WORDPRESS_USER"
else
    echo "[INFO] WordPress já configurado"
fi

chown -R www-data:www-data /var/www/html

echo "[INFO] Iniciando PHP-FPM..."

# -F keeps PHP-FPM in foreground; exec makes it PID 1 for proper signal handling
exec php-fpm8.2 -F
```

### Pontos Importantes

1. **Validação de Admin**: O script verifica se o nome do admin contém "admin" e falha se contiver
2. **Aguarda MariaDB**: Usa loop para esperar o banco estar disponível
3. **WP-CLI**: Usa a ferramenta oficial para instalação automática
4. **Dois Usuários**: Cria o admin e um segundo usuário (editor)
5. **`exec php-fpm8.2 -F`**: O `-F` mantém o PHP-FPM em foreground

---

## 4. Configuração PHP-FPM

### srcs/requirements/wordpress/conf/www.conf

```ini
[www]
user = www-data
group = www-data

listen = 0.0.0.0:9000

listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500

request_terminate_timeout = 300

catch_workers_output = yes
php_admin_flag[log_errors] = on
php_admin_value[error_log] = /var/log/php-fpm-error.log

php_admin_value[memory_limit] = 256M
php_admin_value[upload_max_filesize] = 64M
php_admin_value[post_max_size] = 64M
php_admin_value[max_execution_time] = 300
php_admin_value[max_input_time] = 300
php_admin_value[max_input_vars] = 5000

php_admin_value[expose_php] = Off
php_admin_value[allow_url_fopen] = On
php_admin_value[allow_url_include] = Off

php_admin_value[date.timezone] = America/Sao_Paulo

php_admin_value[session.save_handler] = files
php_admin_value[session.save_path] = /tmp

php_admin_flag[opcache.enable] = 1
php_admin_value[opcache.memory_consumption] = 128
php_admin_value[opcache.interned_strings_buffer] = 8
php_admin_value[opcache.max_accelerated_files] = 10000
php_admin_value[opcache.revalidate_freq] = 2

; Required to preserve environment variables passed from Docker
clear_env = no
```

### Explicação das Configurações

| Configuração                | Propósito                                  |
| --------------------------- | ------------------------------------------ |
| `listen = 0.0.0.0:9000`     | Aceita conexões TCP de qualquer IP         |
| `pm = dynamic`              | Gerenciamento dinâmico de processos        |
| `memory_limit = 256M`       | Limite de memória por processo             |
| `upload_max_filesize = 64M` | Tamanho máximo de upload                   |
| `opcache.enable = 1`        | Cache de bytecode PHP                      |
| `clear_env = no`            | Mantém variáveis de ambiente (importante!) |

---

## 5. Integração com Docker Compose

### Trecho do docker-compose.yml para WordPress

```yaml
services:
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

secrets:
  db_password:
    file: ../secrets/db_password.txt
  credentials:
    file: ../secrets/credentials.txt

volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/peda-cos/data/wordpress
```

### Explicação

| Configuração                                      | Propósito                            |
| ------------------------------------------------- | ------------------------------------ |
| `depends_on: mariadb: condition: service_healthy` | Aguarda MariaDB estar saudável       |
| `secrets: credentials`                            | Senhas do WordPress                  |
| `WORDPRESS_DB_PASSWORD_FILE`                      | Caminho para o secret da senha do DB |

---

## 6. Testes e Validação

### Construir e Testar

```bash
# Navegar até o diretório do projeto
cd inception/srcs

# Construir WordPress (MariaDB já deve estar rodando)
docker compose build wordpress

# Iniciar WordPress
docker compose up -d wordpress

# Ver logs
docker compose logs -f wordpress
```

### Verificar Status

```bash
# Status dos containers
docker compose ps

# Esperado:
# NAME        IMAGE      STATUS
# mariadb     mariadb    Up (healthy)
# wordpress   wordpress  Up (healthy)
```

### Verificar WordPress

```bash
# Acessar o container
docker compose exec wordpress sh

# Verificar WP-CLI
wp --info --allow-root

# Verificar instalação
wp core is-installed --allow-root && echo "WordPress instalado!"

# Listar usuários
wp user list --allow-root

# Sair
exit
```

### Verificar Conexão com MariaDB

```bash
# Do container WordPress, testar conexão
docker compose exec wordpress sh -c "
  mysql -h mariadb -u wpuser -p\$(cat /run/secrets/db_password) -e 'SHOW TABLES;' wordpress
"
```

### Verificar PHP-FPM

```bash
# Verificar se está escutando na porta 9000
docker compose exec wordpress netstat -tlnp | grep 9000

# Ou via PHP
docker compose exec wordpress php -r "echo 'PHP OK\n';"
```

### Verificar Persistência

```bash
# Verificar arquivos no volume
ls -la /home/peda-cos/data/wordpress/

# Deve mostrar arquivos do WordPress:
# wp-admin/, wp-content/, wp-includes/, wp-config.php, etc.
```

### Testar via curl (após NGINX)

```bash
# Este teste funcionará após configurar o NGINX
curl -k https://peda-cos.42.fr
```

---

## Checklist de Validação

- [ ] Container inicia sem erros
- [ ] PHP-FPM escutando na porta 9000
- [ ] WordPress instalado corretamente
- [ ] Dois usuários criados (admin e editor)
- [ ] Nome do admin NÃO contém "admin"
- [ ] Conexão com MariaDB funcionando
- [ ] Arquivos persistem em `/home/peda-cos/data/wordpress`
- [ ] Container reinicia automaticamente
- [ ] Health check retorna "healthy"

---

## Troubleshooting

### WordPress não instala

```bash
# Verificar logs
docker compose logs wordpress

# Verificar conexão com MariaDB
docker compose exec wordpress mysqladmin ping -h mariadb

# Recriar do zero
docker compose down
sudo rm -rf /home/peda-cos/data/wordpress/*
docker compose up -d
```

### Erro de permissão

```bash
# Ajustar permissões
sudo chown -R www-data:www-data /home/peda-cos/data/wordpress/
# Ou com UID/GID
sudo chown -R 33:33 /home/peda-cos/data/wordpress/
```

### PHP-FPM não responde

```bash
# Verificar processo
docker compose exec wordpress pgrep php-fpm

# Verificar configuração
docker compose exec wordpress php-fpm8.2 -t

# Ver logs de erro
docker compose exec wordpress cat /var/log/php-fpm-error.log
```

### Erro "admin" no nome do usuário

O script verifica se o nome do admin contém "admin". Se você definiu um nome inválido:

```bash
# Editar srcs/.env e mudar WORDPRESS_ADMIN_USER
WORDPRESS_ADMIN_USER=supervisor  # Não pode ser admin, administrator, etc.

# Recriar
docker compose down
sudo rm -rf /home/peda-cos/data/wordpress/*
docker compose up -d
```

---

## Próxima Etapa

Com WordPress funcionando, vamos configurar o NGINX:

[Ir para 06-NGINX.md](./06-NGINX.md)
