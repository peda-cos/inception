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
    echo "[ERROR] MYSQL_ROOT_PASSWORD not defined"
    exit 1
fi

if [ -z "$MYSQL_DATABASE" ]; then
    echo "[ERROR] MYSQL_DATABASE not defined"
    exit 1
fi

if [ -z "$MYSQL_USER" ]; then
    echo "[ERROR] MYSQL_USER not defined"
    exit 1
fi

if [ -z "$MYSQL_PASSWORD" ]; then
    echo "[ERROR] MYSQL_PASSWORD not defined"
    exit 1
fi

init_database() {
    echo "[INFO] Initializing database..."

    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null 2>&1

    echo "[INFO] Starting MariaDB temporarily..."

    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    pid="$!"

    echo "[INFO] Waiting for MariaDB to start..."
    for i in $(seq 1 30); do
        if mysqladmin ping --silent 2>/dev/null; then
            break
        fi
        sleep 1
    done

    if ! mysqladmin ping --silent 2>/dev/null; then
        echo "[ERROR] MariaDB did not start correctly"
        exit 1
    fi

    echo "[INFO] Configuring database..."

    cat << EOF > /tmp/init.sql
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

    mysql < /tmp/init.sql

    rm -f /tmp/init.sql

    echo "[INFO] Database configured successfully"
    echo "[INFO] - Database: ${MYSQL_DATABASE}"
    echo "[INFO] - User: ${MYSQL_USER}"

    mysqladmin shutdown

    wait "$pid"

    echo "[INFO] Initialization completed"
}

setup_database_if_needed() {
    echo "[INFO] Checking if database ${MYSQL_DATABASE} exists..."

    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    pid="$!"

    for i in $(seq 1 30); do
        if mysqladmin ping --silent 2>/dev/null; then
            break
        fi
        sleep 1
    done

    if ! mysqladmin ping --silent 2>/dev/null; then
        echo "[ERROR] MariaDB did not start correctly"
        exit 1
    fi

    if ! mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "USE ${MYSQL_DATABASE}" 2>/dev/null; then
        echo "[INFO] Database ${MYSQL_DATABASE} does not exist, creating..."

        cat << EOF > /tmp/setup.sql
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" < /tmp/setup.sql
        rm -f /tmp/setup.sql

        echo "[INFO] Database ${MYSQL_DATABASE} created successfully"
    else
        echo "[INFO] Database ${MYSQL_DATABASE} already exists"
    fi

    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait "$pid"
}

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[INFO] First initialization detected"
    init_database
else
    echo "[INFO] MariaDB already initialized, checking database..."
    setup_database_if_needed
fi

echo "[INFO] Starting MariaDB..."

exec mysqld --user=mysql --datadir=/var/lib/mysql
