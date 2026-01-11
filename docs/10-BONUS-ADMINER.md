# 10 - Bônus: Adminer

[Voltar ao Índice](./00-INDICE.md) | [Anterior: FTP](./09-BONUS-FTP.md)

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Dockerfile](#2-dockerfile)
3. [Docker Compose](#3-docker-compose)
4. [Acesso via NGINX](#4-acesso-via-nginx)
5. [Testes e Validação](#5-testes-e-validação)

---

## 1. Visão Geral

Adminer é uma ferramenta de gerenciamento de banco de dados via web, alternativa leve ao phpMyAdmin.

### Características

- Interface web para gerenciar MariaDB
- Arquivo único PHP
- Leve e rápido
- Suporte a múltiplos bancos

### Arquivos a Criar

```
srcs/requirements/bonus/adminer/
├── Dockerfile
├── .dockerignore
└── conf/
    └── www.conf
```

---

## 2. Dockerfile

### srcs/requirements/bonus/adminer/Dockerfile

```dockerfile
FROM debian:oldstable

RUN apt-get update && apt-get install -y --no-install-recommends \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-mbstring \
    curl \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html \
    && mkdir -p /run/php

RUN curl -L https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php \
    -o /var/www/html/index.php

RUN curl -L https://raw.githubusercontent.com/vrana/adminer/master/designs/nette/adminer.css \
    -o /var/www/html/adminer.css

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

RUN chown -R www-data:www-data /var/www/html

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD pgrep php-fpm > /dev/null || exit 1

CMD ["php-fpm8.2", "-F"]
```

### srcs/requirements/bonus/adminer/conf/www.conf

```ini
[www]
user = www-data
group = www-data

listen = 0.0.0.0:8080
listen.owner = www-data
listen.group = www-data

pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 5

; Required to preserve environment variables passed from Docker
clear_env = no

php_admin_value[memory_limit] = 128M
php_admin_value[upload_max_filesize] = 64M
php_admin_value[post_max_size] = 64M
```

---

## 3. Docker Compose

### Adicionar ao docker-compose.yml

```yaml
services:
  # ... serviços existentes ...

  adminer:
    build:
      context: ./requirements/bonus/adminer
      dockerfile: Dockerfile
    container_name: adminer
    image: adminer
    restart: unless-stopped
    networks:
      - inception
    depends_on:
      - mariadb
    healthcheck:
      test: ["CMD", "pgrep", "php-fpm"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s
```

---

## 4. Acesso via NGINX

Para acessar o Adminer, a abordagem mais simples é expor uma porta separada usando o servidor PHP embutido.

### Opção Recomendada: Porta Separada com PHP Embutido

Atualize o Dockerfile para usar o servidor PHP embutido:

```dockerfile
# Usar servidor PHP embutido (mais simples)
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]
```

E adicione a porta no docker-compose.yml:

```yaml
adminer:
  # ... configuração existente ...
  ports:
    - "8080:8080"
```

**Acesso**: `http://peda-cos.42.fr:8080`

### Opção Alternativa: Via Location no NGINX

Se preferir acessar via HTTPS pelo NGINX, adicione ao `nginx.conf`:

```nginx
        # Adminer (dentro do server block principal)
        location /adminer {
            proxy_pass http://adminer:8080;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
```

**Acesso**: `https://peda-cos.42.fr/adminer`

---

## 5. Testes e Validação

### Iniciar Adminer

```bash
# Construir e iniciar
docker compose -f srcs/docker-compose.yml build adminer
docker compose -f srcs/docker-compose.yml up -d adminer

# Ver logs
docker compose -f srcs/docker-compose.yml logs adminer
```

### Acessar Adminer

1. Abra o navegador: `http://peda-cos.42.fr:8080` (se usando porta separada)
2. Ou: `https://peda-cos.42.fr/adminer` (se usando NGINX)

### Login no Adminer

- **Sistema**: MySQL
- **Servidor**: `mariadb`
- **Usuário**: `wpuser`
- **Senha**: (do arquivo db_password.txt)
- **Base de dados**: `wordpress`

### Verificar Tabelas

Após login, você deve ver as tabelas do WordPress:

- wp_posts
- wp_users
- wp_options
- etc.

---

## Checklist de Validação

- [ ] Container Adminer inicia sem erros
- [ ] Interface web acessível
- [ ] Consegue conectar ao MariaDB
- [ ] Visualiza tabelas do WordPress
- [ ] Consegue executar queries

---

## Troubleshooting

### Não consegue conectar ao banco

```bash
# Testar conexão do container Adminer
docker compose exec adminer php -r "
\$pdo = new PDO('mysql:host=mariadb;dbname=wordpress', 'wpuser', 'SENHA');
echo 'Conectado!';
"
```

### Página em branco

```bash
# Verificar logs PHP
docker compose logs adminer

# Verificar se o arquivo existe
docker compose exec adminer ls -la /var/www/html/
```

---

## Próxima Etapa

[Ir para 11-BONUS-SITE-ESTATICO.md](./11-BONUS-SITE-ESTATICO.md)
