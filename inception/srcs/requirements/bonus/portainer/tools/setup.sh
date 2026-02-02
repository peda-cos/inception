#!/bin/sh

set -e

if [ ! -f /opt/portainer/portainer ]; then
	echo "[ERROR] Portainer binary not found!"
	exit 1
fi

echo "[INFO] Portainer binary found"
echo "[INFO] Data stored in: /data"

if [ -S /var/run/docker.sock ]; then
	echo "[INFO] Docker socket available"
else
	echo "[WARN] Docker socket not found - limited functionality"
fi

echo "[INFO] Starting Portainer on port 9000..."

exec /opt/portainer/portainer --bind=":9000" --data=/data --no-analytics
