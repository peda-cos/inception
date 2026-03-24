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

read_credentials() {
    local key="$1"
    local cred_file="${2:-/run/secrets/credentials}"
    if [ ! -f "$cred_file" ]; then
        echo "[ERROR] Credentials file not found: $cred_file" >&2
        return 1
    fi
    grep "^${key}=" "$cred_file" | cut -d'=' -f2- | tr -d '\n'
}

require_env() {
    local var_name="$1"
    local var_value
    eval "var_value=\$$var_name"
    if [ -z "$var_value" ]; then
        echo "[ERROR] Required environment variable not set: $var_name" >&2
        exit 1
    fi
}

DB_PASSWORD=$(read_secret "${WORDPRESS_DB_PASSWORD_FILE}")
ADMIN_PASSWORD=$(read_credentials "WORDPRESS_ADMIN_PASSWORD")
USER_PASSWORD=$(read_credentials "WORDPRESS_USER_PASSWORD")

require_env ADMIN_PASSWORD
require_env USER_PASSWORD
require_env WORDPRESS_DB_HOST
require_env WORDPRESS_DB_NAME
require_env WORDPRESS_DB_USER
require_env DB_PASSWORD
require_env DOMAIN_NAME

if echo "$WORDPRESS_ADMIN_USER" | grep -iq "admin"; then
    echo "[ERROR] Administrator name cannot contain 'admin'"
    exit 1
fi

DB_HOST="${WORDPRESS_DB_HOST%%:*}"
DB_PORT="${WORDPRESS_DB_HOST##*:}"
if [ "$DB_PORT" = "$DB_HOST" ]; then
    DB_PORT=3306
fi

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
    if wp user get "$WORDPRESS_USER" --allow-root > /dev/null 2>&1; then
        echo "[INFO] User $WORDPRESS_USER already exists, skipping"
    else
        wp user create \
            "$WORDPRESS_USER" \
            "$WORDPRESS_USER_EMAIL" \
            --role="${WORDPRESS_USER_ROLE:-editor}" \
            --user_pass="$USER_PASSWORD" \
            --allow-root
    fi

    wp rewrite structure '/%postname%/' --allow-root
    wp rewrite flush --allow-root

    wp theme activate twentytwentythree --allow-root || echo "[WARN] theme activation failed (non-critical)"

    wp language core update --allow-root || echo "[WARN] language update failed (non-critical)"

    if [ -n "$REDIS_HOST" ]; then
        echo "[INFO] Installing Redis Object Cache plugin..."
        wp plugin install redis-cache --activate --allow-root
        wp redis enable --allow-root || echo "[WARN] redis enable failed (non-critical)"
        echo "[INFO] Redis Object Cache plugin activated"
    fi

    echo "[INFO] WordPress installed successfully!"
    echo "[INFO] - URL: https://${DOMAIN_NAME}"
    echo "[INFO] - Admin: $WORDPRESS_ADMIN_USER"
    echo "[INFO] - User: $WORDPRESS_USER"

    chown -R www-data:www-data /var/www/html
else
    echo "[INFO] WordPress already configured"
fi

echo "[INFO] Starting PHP-FPM..."
exec php-fpm8.2 -F
