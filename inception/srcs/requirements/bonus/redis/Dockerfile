FROM debian:oldstable

RUN apt-get update && apt-get install -y --no-install-recommends redis-server procps && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/redis && mkdir -p /var/lib/redis && chown -R redis:redis /var/run/redis && chown -R redis:redis /var/lib/redis

COPY conf/redis.conf /etc/redis/redis.conf

COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 6379

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 CMD redis-cli ping | grep -q PONG || exit 1

ENTRYPOINT ["/usr/local/bin/init.sh"]
