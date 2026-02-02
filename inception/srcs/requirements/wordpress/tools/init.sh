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
    echo "[ERROR] WORDPRESS_ADMIN_PASSWORD not defined"
    exit 1
fi

if [ -z "$USER_PASSWORD" ]; then
    echo "[ERROR] WORDPRESS_USER_PASSWORD not defined"
    exit 1
fi

if [ -z "$WORDPRESS_DB_HOST" ]; then
    echo "[ERROR] WORDPRESS_DB_HOST not defined"
    exit 1
fi

if [ -z "$WORDPRESS_DB_NAME" ]; then
    echo "[ERROR] WORDPRESS_DB_NAME not defined"
    exit 1
fi

if [ -z "$WORDPRESS_DB_USER" ]; then
    echo "[ERROR] WORDPRESS_DB_USER not defined"
    exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
    echo "[ERROR] DB_PASSWORD not defined"
    exit 1
fi

if [ -z "$DOMAIN_NAME" ]; then
    echo "[ERROR] DOMAIN_NAME not defined"
    exit 1
fi

if echo "$WORDPRESS_ADMIN_USER" | grep -iq "admin"; then
    echo "[ERROR] Administrator name cannot contain 'admin'"
    exit 1
fi

DB_HOST=$(echo "$WORDPRESS_DB_HOST" | cut -d':' -f1)
DB_PORT=$(echo "$WORDPRESS_DB_HOST" | cut -d':' -f2)
DB_PORT=${DB_PORT:-3306}

echo "[INFO] Waiting for MariaDB at $DB_HOST:$DB_PORT..."
max_attempts=60
attempt=0
while ! mysqladmin ping -h "$DB_HOST" -P "$DB_PORT" --silent 2>/dev/null; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "[ERROR] MariaDB did not respond after $max_attempts attempts"
        exit 1
    fi
    echo "[INFO] Attempt $attempt/$max_attempts..."
    sleep 2
done
echo "[INFO] MariaDB is ready!"

cd /var/www/html

if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "[INFO] First initialization - Configuring WordPress..."

    if [ ! -f "/var/www/html/wp-load.php" ]; then
        echo "[INFO] Downloading WordPress..."
        wp core download --allow-root --locale=en_US --version=6.7
    fi

    echo "[INFO] Creating wp-config.php..."
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

    echo "[INFO] Installing WordPress..."
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WORDPRESS_TITLE:-Inception}" \
        --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$ADMIN_PASSWORD" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    echo "[INFO] Creating second user..."
    wp user create \
        "$WORDPRESS_USER" \
        "$WORDPRESS_USER_EMAIL" \
        --role="${WORDPRESS_USER_ROLE:-editor}" \
        --user_pass="$USER_PASSWORD" \
        --allow-root || echo "[WARN] User already exists"

    wp rewrite structure '/%postname%/' --allow-root
    wp rewrite flush --allow-root

    wp theme activate twentytwentythree --allow-root 2>/dev/null || true

    wp language core update --allow-root 2>/dev/null || true

    echo "[INFO] WordPress installed successfully!"
    echo "[INFO] - URL: https://${DOMAIN_NAME}"
    echo "[INFO] - Admin: $WORDPRESS_ADMIN_USER"
    echo "[INFO] - User: $WORDPRESS_USER"
else
    echo "[INFO] WordPress already configured"
fi

chown -R www-data:www-data /var/www/html

echo "[INFO] Starting PHP-FPM..."
exec php-fpm8.2 -F
