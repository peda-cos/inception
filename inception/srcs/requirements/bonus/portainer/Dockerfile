# srcs/requirements/bonus/portainer/Dockerfile

FROM debian:oldstable

LABEL maintainer="peda-cos@student.42sp.org.br"
LABEL description="Portainer CE for Docker management - 42 Inception"
LABEL version="1.0"

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates procps && rm -rf /var/lib/apt/lists/*

RUN curl -L "https://github.com/portainer/portainer/releases/download/2.33.6/portainer-2.33.6-linux-amd64.tar.gz" -o /tmp/portainer.tar.gz && tar -xzf /tmp/portainer.tar.gz -C /opt && rm /tmp/portainer.tar.gz && chmod +x /opt/portainer/portainer

RUN mkdir -p /data

COPY tools/setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 CMD curl -f http://localhost:9000/api/status || exit 1

ENTRYPOINT ["/usr/local/bin/setup.sh"]
