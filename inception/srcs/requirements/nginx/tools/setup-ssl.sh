#!/bin/bash
set -e

SSL_DIR="/etc/nginx/ssl"
BASE_DOMAIN="${DOMAIN_NAME:-peda-cos.42.fr}"
DAYS_VALID=365

echo "[INFO] Generating SSL certificate for: $BASE_DOMAIN"

mkdir -p "$SSL_DIR"

openssl req -x509 \
    -nodes \
    -days "$DAYS_VALID" \
    -newkey rsa:2048 \
    -keyout "$SSL_DIR/inception.key" \
    -out "$SSL_DIR/inception.crt" \
    -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=42SP/OU=Inception/CN=$BASE_DOMAIN" \
    -addext "subjectAltName=DNS:$BASE_DOMAIN,DNS:www.$BASE_DOMAIN,DNS:adminer.$BASE_DOMAIN,DNS:static.$BASE_DOMAIN,DNS:portainer.$BASE_DOMAIN,DNS:*.$BASE_DOMAIN,IP:127.0.0.1"

openssl dhparam -out "$SSL_DIR/dhparam.pem" 2048

chmod 600 "$SSL_DIR/inception.key"
chmod 644 "$SSL_DIR/inception.crt"

echo "[INFO] Certificates generated in $SSL_DIR"
ls -la "$SSL_DIR"
