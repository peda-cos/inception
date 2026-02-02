#!/bin/sh
set -e

echo "[INFO] Starting Redis..."

chown -R redis:redis /var/lib/redis
chown -R redis:redis /var/run/redis

exec redis-server /etc/redis/redis.conf
