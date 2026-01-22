FROM debian:oldstable

RUN apt-get update && apt-get install -y --no-install-recommends vsftpd procps && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/vsftpd/empty && mkdir -p /var/log/vsftpd && mkdir -p /etc/vsftpd

COPY conf/vsftpd.conf /etc/vsftpd.conf

COPY tools/init.sh /usr/local/bin/init.sh

COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 21
EXPOSE 21100-21110

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 CMD pgrep vsftpd > /dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/init.sh"]
