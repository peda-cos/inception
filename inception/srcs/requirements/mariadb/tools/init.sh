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
