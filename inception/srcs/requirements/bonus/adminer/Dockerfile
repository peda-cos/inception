FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-mbstring \
    lighttpd \
    curl \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html && mkdir -p /run/php

RUN curl -L https://github.com/vrana/adminer/releases/download/v5.4.0/adminer-5.4.0.php -o /var/www/html/index.php

RUN curl -L https://raw.githubusercontent.com/vrana/adminer/master/designs/nette/adminer.css -o /var/www/html/adminer.css

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY conf/lighttpd.conf /etc/lighttpd/lighttpd.conf

COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

RUN chown -R www-data:www-data /var/www/html

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 CMD curl -f http://localhost:8080/ || exit 1

ENTRYPOINT ["/usr/local/bin/init.sh"]
