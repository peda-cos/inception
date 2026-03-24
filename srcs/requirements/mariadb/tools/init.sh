#!/bin/bash
set -e

read_secret() {
    local secret_file="$1"
    if [ ! -f "$secret_file" ]; then
        echo "[ERROR] Secret file not found: $secret_file" >&2
        return 1
    fi
    tr -d '\n' < "$secret_file"
}

require_env() {
    local var_name="$1"
    local var_value="${!var_name}"
    if [ -z "$var_value" ]; then
        echo "[ERROR] Required environment variable not set: $var_name" >&2
        exit 1
    fi
}

MYSQL_ROOT_PASSWORD=$(read_secret "${MYSQL_ROOT_PASSWORD_FILE}")
MYSQL_PASSWORD=$(read_secret "${MYSQL_PASSWORD_FILE}")

require_env MYSQL_ROOT_PASSWORD
require_env MYSQL_DATABASE
require_env MYSQL_USER
require_env MYSQL_PASSWORD

wait_for_mysqld() {
    echo "[INFO] Waiting for MariaDB to start..."
    local i=1
    while [ "$i" -le 30 ]; do
        if mysqladmin ping --silent 2>/dev/null; then
            return 0
        fi
        sleep 1
        i=$((i + 1))
    done
    echo "[ERROR] MariaDB did not start correctly" >&2
    exit 1
}

create_db_and_user() {
    echo "[INFO] Creating database and user..."
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
		FLUSH PRIVILEGES;
	EOSQL
}

init_database() {
    echo "[INFO] Initializing database..."

    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "[INFO] Starting MariaDB temporarily..."
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    pid="$!"

    wait_for_mysqld

    echo "[INFO] Configuring database..."

    mysql <<-EOSQL
		ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD('${MYSQL_ROOT_PASSWORD}');
		FLUSH PRIVILEGES;
	EOSQL

    create_db_and_user

    echo "[INFO] Database configured successfully"
    echo "[INFO] - Database: ${MYSQL_DATABASE}"
    echo "[INFO] - User: ${MYSQL_USER}"

    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait "$pid"

    echo "[INFO] Initialization completed"
}

setup_database_if_needed() {
    echo "[INFO] Checking if database ${MYSQL_DATABASE} exists..."

    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    local MYSQLD_PID="$!"
    trap 'kill $MYSQLD_PID 2>/dev/null; wait $MYSQLD_PID 2>/dev/null' EXIT

    wait_for_mysqld

    if ! mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "USE \`${MYSQL_DATABASE}\`" 2>/dev/null; then
        echo "[INFO] Database ${MYSQL_DATABASE} does not exist, creating..."
        create_db_and_user
        echo "[INFO] Database ${MYSQL_DATABASE} created successfully"
    else
        echo "[INFO] Database ${MYSQL_DATABASE} already exists"
    fi

    trap - EXIT
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait "$MYSQLD_PID"
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
