# 04 - MariaDB

[Voltar ao Índice](./00-INDICE.md) | [Anterior: Estrutura](./03-ESTRUTURA-PROJETO.md)

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Dockerfile](#2-dockerfile)
3. [Script de Inicialização](#3-script-de-inicialização)
4. [Configuração do MariaDB](#4-configuração-do-mariadb)
5. [Integração com Docker Compose](#5-integração-com-docker-compose)
6. [Testes e Validação](#6-testes-e-validação)

---

## 1. Visão Geral

O container MariaDB é responsável por:

- Armazenar o banco de dados do WordPress
- Persistir dados em volume externo
- Aceitar conexões apenas da rede interna Docker

### Requisitos do Subject

- Container dedicado apenas para MariaDB (sem nginx)
- Dados persistidos em `/home/peda-cos/data/mariadb`
- Dois usuários: root e usuário do WordPress
- Reiniciar automaticamente em caso de crash
- Sem senhas hardcoded no Dockerfile

### Arquivos a Criar

```
srcs/requirements/mariadb/
├── Dockerfile
├── .dockerignore
├── conf/
│   └── 50-server.cnf
└── tools/
    └── init.sh
```

---

## 2. Dockerfile

### srcs/requirements/mariadb/Dockerfile

```dockerfile
FROM debian:oldstable

RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-server \
    mariadb-client \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/mysqld \
    && chown -R mysql:mysql /var/run/mysqld \
    && chmod 755 /var/run/mysqld

RUN mkdir -p /var/lib/mysql \
    && chown -R mysql:mysql /var/lib/mysql

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 3306

HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
    CMD mysqladmin ping -h localhost --silent || exit 1

ENTRYPOINT ["/usr/local/bin/init.sh"]
```

### Explicação das Instruções

| Instrução                        | Propósito                           |
| -------------------------------- | ----------------------------------- |
| `FROM debian:oldstable`          | Base Debian penúltima estável       |
| `apt-get install mariadb-server` | Instala o servidor MariaDB          |
| `mkdir /var/run/mysqld`          | Cria diretório para socket          |
| `chown mysql:mysql`              | Define permissões corretas          |
| `COPY conf/`                     | Copia configuração customizada      |
| `COPY tools/init.sh`             | Script de inicialização             |
| `EXPOSE 3306`                    | Documenta porta padrão              |
| `HEALTHCHECK`                    | Verifica se o serviço está saudável |
| `ENTRYPOINT`                     | Define script de inicialização      |

---

## 3. Script de Inicialização

Este script é **crucial** para configurar o banco na primeira execução.

### srcs/requirements/mariadb/tools/init.sh

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

MYSQL_ROOT_PASSWORD=$(read_secret "${MYSQL_ROOT_PASSWORD_FILE}")
MYSQL_PASSWORD=$(read_secret "${MYSQL_PASSWORD_FILE}")

if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    echo "[ERROR] MYSQL_ROOT_PASSWORD não definido"
    exit 1
fi

if [ -z "$MYSQL_DATABASE" ]; then
    echo "[ERROR] MYSQL_DATABASE não definido"
    exit 1
fi

if [ -z "$MYSQL_USER" ]; then
    echo "[ERROR] MYSQL_USER não definido"
    exit 1
fi

if [ -z "$MYSQL_PASSWORD" ]; then
    echo "[ERROR] MYSQL_PASSWORD não definido"
    exit 1
fi

init_database() {
    echo "[INFO] Inicializando banco de dados..."

    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null 2>&1

    echo "[INFO] Iniciando MariaDB temporariamente..."

    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    pid="$!"

    echo "[INFO] Aguardando MariaDB iniciar..."
    for i in $(seq 1 30); do
        if mysqladmin ping --silent 2>/dev/null; then
            break
        fi
        sleep 1
    done

    if ! mysqladmin ping --silent 2>/dev/null; then
        echo "[ERROR] MariaDB não iniciou corretamente"
        exit 1
    fi

    echo "[INFO] Configurando banco de dados..."

    cat << EOF > /tmp/init.sql
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

    mysql < /tmp/init.sql

    rm -f /tmp/init.sql

    echo "[INFO] Banco de dados configurado com sucesso"
    echo "[INFO] - Database: ${MYSQL_DATABASE}"
    echo "[INFO] - User: ${MYSQL_USER}"

    mysqladmin shutdown

    wait "$pid"

    echo "[INFO] Inicialização concluída"
}

setup_database_if_needed() {
    echo "[INFO] Verificando se database ${MYSQL_DATABASE} existe..."

    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    pid="$!"

    for i in $(seq 1 30); do
        if mysqladmin ping --silent 2>/dev/null; then
            break
        fi
        sleep 1
    done

    if ! mysqladmin ping --silent 2>/dev/null; then
        echo "[ERROR] MariaDB não iniciou corretamente"
        exit 1
    fi

    if ! mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "USE ${MYSQL_DATABASE}" 2>/dev/null; then
        echo "[INFO] Database ${MYSQL_DATABASE} não existe, criando..."

        cat << EOF > /tmp/setup.sql
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" < /tmp/setup.sql
        rm -f /tmp/setup.sql

        echo "[INFO] Database ${MYSQL_DATABASE} criada com sucesso"
    else
        echo "[INFO] Database ${MYSQL_DATABASE} já existe"
    fi

    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait "$pid"
}

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[INFO] Primeira inicialização detectada"
    init_database
else
    echo "[INFO] MariaDB já inicializado, verificando database..."
    setup_database_if_needed
fi

echo "[INFO] Iniciando MariaDB..."

# exec replaces shell with mysqld, making it PID 1 for proper signal handling
exec mysqld --user=mysql --datadir=/var/lib/mysql
```

### Pontos Importantes do Script

1. **Leitura de Secrets**: Usa arquivos em vez de variáveis de ambiente diretas
2. **Validação**: Verifica se todas as variáveis necessárias estão definidas
3. **Primeira Inicialização**: Detecta se é a primeira vez e configura o banco
4. **Verificação de Database**: Mesmo com dados existentes, verifica se a database do WordPress existe
5. **Configuração Segura**: Usa arquivo SQL temporário que é deletado após uso
6. **`exec` no final**: Substitui o shell pelo mysqld para gerenciamento correto de PID 1

---

## 4. Configuração do MariaDB

### srcs/requirements/mariadb/conf/50-server.cnf

```ini
[mysqld]
datadir                 = /var/lib/mysql
socket                  = /var/run/mysqld/mysqld.sock
bind-address            = 0.0.0.0
port                    = 3306
user                    = mysql
character-set-server    = utf8mb4
collation-server        = utf8mb4_unicode_ci

# Improves performance by avoiding DNS lookups
skip-name-resolve
max_connections         = 100
connect_timeout         = 10
wait_timeout            = 600
max_allowed_packet      = 64M

innodb_buffer_pool_size = 128M
innodb_log_file_size    = 48M
innodb_file_per_table   = 1

log_error               = /var/lib/mysql/error.log
slow_query_log          = 0

# Query cache is deprecated in modern MariaDB/MySQL
query_cache_type        = 0
query_cache_size        = 0

[client]
socket                  = /var/run/mysqld/mysqld.sock
default-character-set   = utf8mb4

[mysql]
default-character-set   = utf8mb4
```

### Explicação das Configurações

| Configuração                     | Propósito                                    |
| -------------------------------- | -------------------------------------------- |
| `bind-address = 0.0.0.0`         | Aceita conexões de qualquer IP (rede Docker) |
| `skip-name-resolve`              | Melhora performance evitando DNS lookup      |
| `character-set-server = utf8mb4` | Suporte completo a Unicode                   |
| `innodb_buffer_pool_size`        | Cache de dados InnoDB                        |
| `max_allowed_packet = 64M`       | Tamanho máximo de pacotes                    |

---

## 5. Integração com Docker Compose

### Trecho do docker-compose.yml para MariaDB

```yaml
services:
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

secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt

volumes:
  db_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/peda-cos/data/mariadb

networks:
  inception:
    driver: bridge
```

### Explicação

| Configuração              | Propósito                                        |
| ------------------------- | ------------------------------------------------ |
| `restart: unless-stopped` | Reinicia em caso de crash (requisito do subject) |
| `networks: inception`     | Rede isolada entre containers                    |
| `volumes: db_data`        | Persistência em `/home/peda-cos/data/mariadb`    |
| `secrets`                 | Senhas seguras via arquivos                      |
| `healthcheck`             | Verifica saúde do container                      |

---

## 6. Testes e Validação

### Construir e Testar Isoladamente

```bash
# Navegar até o diretório do projeto
cd inception/srcs

# Construir apenas o MariaDB
docker compose build mariadb

# Iniciar apenas o MariaDB
docker compose up -d mariadb

# Ver logs
docker compose logs -f mariadb
```

### Verificar se o Container Está Rodando

```bash
# Status
docker compose ps

# Saída esperada:
# NAME      IMAGE     COMMAND              SERVICE   STATUS
# mariadb   mariadb   "/usr/local/bin/..."  mariadb   Up (healthy)
```

### Testar Conexão

```bash
# Acessar o container
docker compose exec mariadb sh

# Dentro do container, conectar ao MySQL
mysql -u wpuser -p
# Digite a senha do arquivo db_password.txt

# Verificar banco de dados
SHOW DATABASES;
# Deve mostrar 'wordpress'

# Sair
exit
exit
```

### Testar via MySQL Client

```bash
# Do host (se tiver mysql-client instalado)
mysql -h 127.0.0.1 -P 3306 -u wpuser -p wordpress

# Ou via Docker
docker compose exec mariadb mysql -u wpuser -p -e "SHOW DATABASES;"
```

### Verificar Persistência

```bash
# Verificar se dados estão no volume
ls -la /home/peda-cos/data/mariadb/

# Deve mostrar arquivos do MariaDB:
# ibdata1, ib_logfile0, ib_logfile1, wordpress/, mysql/, etc.
```

### Testar Restart

```bash
# Parar o container
docker compose stop mariadb

# Iniciar novamente
docker compose start mariadb

# Verificar se dados persistiram
docker compose exec mariadb mysql -u wpuser -p -e "SHOW DATABASES;"
# Deve ainda mostrar 'wordpress'
```

### Verificar Health Check

```bash
# Ver status de saúde
docker inspect --format='{{.State.Health.Status}}' mariadb
# Deve retornar: healthy

# Ver histórico de health checks
docker inspect --format='{{json .State.Health}}' mariadb | jq
```

---

## Checklist de Validação

- [ ] Container inicia sem erros
- [ ] Banco de dados `wordpress` existe
- [ ] Usuário `wpuser` consegue conectar
- [ ] Dados persistem em `/home/peda-cos/data/mariadb`
- [ ] Container reinicia automaticamente em caso de crash
- [ ] Health check retorna "healthy"
- [ ] Nenhuma senha hardcoded no Dockerfile
- [ ] Usando secrets para senhas

---

## Troubleshooting

### Container não inicia

```bash
# Ver logs
docker compose logs mariadb

# Verificar permissões do volume
ls -la /home/peda-cos/data/mariadb/
sudo chown -R 999:999 /home/peda-cos/data/mariadb/
```

### Erro de permissão

```bash
# O usuário mysql dentro do container tem UID 999
sudo chown -R 999:999 /home/peda-cos/data/mariadb/
```

### Não consegue conectar

```bash
# Verificar se o container está healthy
docker compose ps

# Verificar se o socket existe
docker compose exec mariadb ls -la /var/run/mysqld/

# Verificar logs de erro
docker compose exec mariadb cat /var/lib/mysql/error.log
```

### Senha incorreta

```bash
# Verificar se o secret está correto
cat secrets/db_password.txt

# Recriar o container do zero
docker compose down -v
sudo rm -rf /home/peda-cos/data/mariadb/*
docker compose up -d mariadb
```

---

## Próxima Etapa

Com o MariaDB funcionando, vamos implementar o WordPress:

[Ir para 05-WORDPRESS.md](./05-WORDPRESS.md)
