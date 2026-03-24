FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    openssl \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Create required directories first, then generate DH params as cached layer
# (before any COPY so this layer is reused on config-only rebuilds)
RUN mkdir -p /etc/nginx/ssl \
    && mkdir -p /var/www/html \
    && mkdir -p /var/log/nginx \
    && mkdir -p /run/nginx \
    && mkdir -p /var/cache/nginx/wordpress \
    && chown -R www-data:www-data /var/www/html \
    && chown -R www-data:www-data /var/log/nginx \
    && chown -R www-data:www-data /var/cache/nginx \
    && openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

COPY tools/setup-ssl.sh /usr/local/bin/setup-ssl.sh
RUN chmod +x /usr/local/bin/setup-ssl.sh

RUN /usr/local/bin/setup-ssl.sh

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -fsk https://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
