FROM debian:oldstable

RUN apt-get update && apt-get install -y --no-install-recommends nginx curl procps && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/static && mkdir -p /run/nginx

COPY www/ /var/www/static/

COPY conf/nginx.conf /etc/nginx/nginx.conf

RUN chown -R www-data:www-data /var/www/static

EXPOSE 8081

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 CMD curl -f http://localhost:8081/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
