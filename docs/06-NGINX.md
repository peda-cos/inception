# 06 - NGINX com TLS

[Voltar ao Índice](./00-INDICE.md) | [Anterior: WordPress](./05-WORDPRESS.md)

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Dockerfile](#2-dockerfile)
3. [Script de SSL](#3-script-de-ssl)
4. [Configuração NGINX](#4-configuração-nginx)
5. [Integração com Docker Compose](#5-integração-com-docker-compose)
6. [Testes e Validação](#6-testes-e-validação)

---

## 1. Visão Geral

O container NGINX é o **único ponto de entrada** da infraestrutura:

- Porta 443 (HTTPS) - **ÚNICA porta exposta**
- TLSv1.2 ou TLSv1.3 **apenas** (requisito do subject)
- Reverse proxy para WordPress PHP-FPM
- Certificado SSL autoassinado para `peda-cos.42.fr`

### Requisitos do Subject

- NGINX com TLSv1.2 ou TLSv1.3 **apenas**
- Único ponto de entrada via porta 443
- Sem outras portas expostas para o host
- Container dedicado (sem WordPress dentro)

### Arquivos a Criar

```
srcs/requirements/nginx/
├── Dockerfile
├── .dockerignore
├── conf/
│   └── nginx.conf
└── tools/
    └── setup-ssl.sh
```

---

## 2. Dockerfile

### srcs/requirements/nginx/Dockerfile

```dockerfile
FROM debian:oldstable

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    openssl \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl \
    && mkdir -p /var/www/html \
    && mkdir -p /var/log/nginx \
    && mkdir -p /run/nginx

COPY tools/setup-ssl.sh /usr/local/bin/setup-ssl.sh
RUN chmod +x /usr/local/bin/setup-ssl.sh

RUN /usr/local/bin/setup-ssl.sh

COPY conf/nginx.conf /etc/nginx/nginx.conf

RUN chown -R www-data:www-data /var/www/html \
    && chown -R www-data:www-data /var/log/nginx

EXPOSE 443

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -fsk https://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

### Explicação das Instruções

| Instrução        | Propósito                                  |
| ---------------- | ------------------------------------------ |
| `nginx`          | Servidor web/reverse proxy                 |
| `openssl`        | Para gerar certificados SSL                |
| `curl`           | Para health check (verificar HTTPS)        |
| `procps`         | Para comandos ps/pgrep (verificar PID 1)   |
| `/etc/nginx/ssl` | Diretório para certificados                |
| `setup-ssl.sh`   | Script para gerar certificado autoassinado |
| `EXPOSE 443`     | Única porta exposta                        |
| `daemon off;`    | Mantém NGINX em foreground (PID 1)         |

---

## 3. Script de SSL

Este script gera o certificado autoassinado para o domínio.

### srcs/requirements/nginx/tools/setup-ssl.sh

```bash
#!/bin/bash
set -e

SSL_DIR="/etc/nginx/ssl"
DOMAIN="${DOMAIN_NAME:-peda-cos.42.fr}"
DAYS_VALID=365

echo "[INFO] Gerando certificado SSL para: $DOMAIN"

mkdir -p "$SSL_DIR"

openssl req -x509 \
    -nodes \
    -days $DAYS_VALID \
    -newkey rsa:2048 \
    -keyout "$SSL_DIR/inception.key" \
    -out "$SSL_DIR/inception.crt" \
    -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=42SP/OU=Inception/CN=$DOMAIN" \
    -addext "subjectAltName=DNS:$DOMAIN,DNS:www.$DOMAIN,IP:127.0.0.1"

# DH params generation is slow; uncomment for production-grade forward secrecy
# openssl dhparam -out "$SSL_DIR/dhparam.pem" 2048

chmod 600 "$SSL_DIR/inception.key"
chmod 644 "$SSL_DIR/inception.crt"

echo "[INFO] Certificados gerados em $SSL_DIR"
ls -la "$SSL_DIR"
```

### Explicação do Comando OpenSSL

| Parâmetro          | Propósito                      |
| ------------------ | ------------------------------ |
| `-x509`            | Gerar certificado autoassinado |
| `-nodes`           | Sem senha na chave privada     |
| `-days 365`        | Validade de 1 ano              |
| `-newkey rsa:2048` | Chave RSA de 2048 bits         |
| `-subj`            | Informações do certificado     |
| `subjectAltName`   | Nomes alternativos (DNS e IP)  |

---

## 4. Configuração NGINX

### srcs/requirements/nginx/conf/nginx.conf

```nginx
user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log warn;

events {
    worker_connections 1024;
    multi_accept on;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    server_tokens off;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript
               application/xml application/xml+rss text/javascript;

    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        server_name peda-cos.42.fr www.peda-cos.42.fr;

        ssl_certificate /etc/nginx/ssl/inception.crt;
        ssl_certificate_key /etc/nginx/ssl/inception.key;

        # Subject requirement: only TLSv1.2 and TLSv1.3 allowed
        ssl_protocols TLSv1.2 TLSv1.3;

        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;

        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 1d;
        ssl_session_tickets off;

        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        root /var/www/html;
        index index.php index.html index.htm;

        location /health {
            access_log off;
            return 200 "OK\n";
            add_header Content-Type text/plain;
        }

        location / {
            try_files $uri $uri/ /index.php?$args;
        }

        location ~ \.php$ {
            try_files $uri =404;

            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass wordpress:9000;
            fastcgi_index index.php;
            fastcgi_read_timeout 300;

            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO $fastcgi_path_info;
            fastcgi_param HTTPS on;

            fastcgi_buffer_size 128k;
            fastcgi_buffers 256 16k;
            fastcgi_busy_buffers_size 256k;
            fastcgi_temp_file_write_size 256k;
        }

        location ~ /\. {
            deny all;
            access_log off;
            log_not_found off;
        }

        location ~* ^/(wp-config\.php|readme\.html|license\.txt) {
            deny all;
        }

        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            access_log off;
        }

        client_max_body_size 64M;

        client_body_timeout 300;
        send_timeout 300;
    }

    # Subject requires only port 443; uncomment to redirect HTTP if port 80 is exposed
    # server {
    #     listen 80;
    #     listen [::]:80;
    #     server_name peda-cos.42.fr www.peda-cos.42.fr;
    #     return 301 https://$server_name$request_uri;
    # }
}
```

### Pontos Críticos da Configuração

| Configuração                     | Importância                           |
| -------------------------------- | ------------------------------------- |
| `ssl_protocols TLSv1.2 TLSv1.3;` | **CRÍTICO** - Apenas estes protocolos |
| `listen 443 ssl http2;`          | Porta única, HTTPS com HTTP/2         |
| `fastcgi_pass wordpress:9000;`   | Conexão com container WordPress       |
| `server_tokens off;`             | Não expor versão do NGINX             |
| `client_max_body_size 64M;`      | Permitir uploads grandes              |

---

## 5. Integração com Docker Compose

### Trecho do docker-compose.yml para NGINX

```yaml
services:
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
```

### Explicação

| Configuração                               | Propósito                               |
| ------------------------------------------ | --------------------------------------- |
| `ports: "443:443"`                         | **ÚNICA** porta exposta ao host         |
| `volumes: wordpress_data:/var/www/html:ro` | Acesso read-only aos arquivos WordPress |
| `depends_on: wordpress`                    | Aguarda WordPress estar pronto          |

---

## 6. Testes e Validação

### Construir e Testar

```bash
# Navegar até o diretório do projeto
cd inception/srcs

# Construir todos os serviços
docker compose build

# Iniciar todos os serviços
docker compose up -d

# Ver logs
docker compose logs -f nginx
```

### Verificar Status

```bash
# Status dos containers
docker compose ps

# Esperado:
# NAME        IMAGE      STATUS
# mariadb     mariadb    Up (healthy)
# wordpress   wordpress  Up (healthy)
# nginx       nginx      Up (healthy)
```

### Testar Acesso HTTPS

```bash
# Via curl (ignorando certificado autoassinado)
curl -k https://peda-cos.42.fr

# Verificar resposta
curl -k -I https://peda-cos.42.fr
```

### Verificar TLS

Este é um teste **crítico** para a avaliação:

```bash
# Testar TLSv1.2
openssl s_client -connect peda-cos.42.fr:443 -tls1_2 < /dev/null 2>/dev/null | grep -E "Protocol|Cipher"

# Esperado:
# Protocol  : TLSv1.2
# Cipher    : ECDHE-RSA-AES256-GCM-SHA384 (ou similar)

# Testar TLSv1.3
openssl s_client -connect peda-cos.42.fr:443 -tls1_3 < /dev/null 2>/dev/null | grep -E "Protocol|Cipher"

# Esperado:
# Protocol  : TLSv1.3
```

### Verificar que TLSv1.0 e TLSv1.1 são REJEITADOS

```bash
# Testar TLSv1.1 (DEVE FALHAR)
openssl s_client -connect peda-cos.42.fr:443 -tls1_1 < /dev/null 2>&1

# Esperado: erro de handshake ou "no protocols available"

# Testar TLSv1.0 (DEVE FALHAR)
openssl s_client -connect peda-cos.42.fr:443 -tls1 < /dev/null 2>&1

# Esperado: erro de handshake ou "no protocols available"
```

### Verificar Certificado

```bash
# Ver detalhes do certificado
openssl s_client -connect peda-cos.42.fr:443 < /dev/null 2>/dev/null | openssl x509 -noout -text

# Verificar domínio no certificado
openssl s_client -connect peda-cos.42.fr:443 < /dev/null 2>/dev/null | openssl x509 -noout -subject

# Esperado:
# subject=C = BR, ST = Sao Paulo, L = Sao Paulo, O = 42SP, OU = Inception, CN = peda-cos.42.fr
```

### Testar Health Check

```bash
# Via curl
curl -k https://peda-cos.42.fr/health
# Esperado: OK

# Via Docker
docker inspect --format='{{.State.Health.Status}}' nginx
# Esperado: healthy
```

### Acessar via Navegador

1. Abra o navegador na VM ou configure port forwarding
2. Acesse: `https://peda-cos.42.fr`
3. Aceite o aviso de certificado autoassinado
4. Você deve ver o WordPress instalado

---

## Checklist de Validação

- [ ] Container NGINX inicia sem erros
- [ ] Porta 443 acessível
- [ ] TLSv1.2 funciona
- [ ] TLSv1.3 funciona
- [ ] TLSv1.0 é **rejeitado**
- [ ] TLSv1.1 é **rejeitado**
- [ ] Certificado válido para `peda-cos.42.fr`
- [ ] WordPress carrega corretamente via HTTPS
- [ ] Arquivos estáticos são servidos
- [ ] Health check retorna "healthy"
- [ ] Apenas porta 443 exposta (verificar com `docker ps`)

---

## Troubleshooting

### NGINX não inicia

```bash
# Verificar logs
docker compose logs nginx

# Testar configuração
docker compose exec nginx nginx -t
```

### Erro de certificado

```bash
# Regenerar certificados
docker compose exec nginx /usr/local/bin/setup-ssl.sh

# Reiniciar
docker compose restart nginx
```

### 502 Bad Gateway

```bash
# Verificar se WordPress está rodando
docker compose ps wordpress

# Verificar se PHP-FPM está escutando
docker compose exec wordpress netstat -tlnp | grep 9000

# Verificar logs do WordPress
docker compose logs wordpress
```

### TLSv1.0 ou TLSv1.1 aceitos

Verifique a configuração do NGINX:

```bash
# Ver configuração atual
docker compose exec nginx grep -i "ssl_protocols" /etc/nginx/nginx.conf

# Deve mostrar APENAS:
# ssl_protocols TLSv1.2 TLSv1.3;
```

### Arquivos estáticos não carregam

```bash
# Verificar volume montado
docker compose exec nginx ls -la /var/www/html/

# Verificar permissões
docker compose exec nginx ls -la /var/www/html/wp-content/
```

---

## Próxima Etapa

Agora vamos juntar tudo no docker-compose.yml final:

[Ir para 07-DOCKER-COMPOSE.md](./07-DOCKER-COMPOSE.md)
