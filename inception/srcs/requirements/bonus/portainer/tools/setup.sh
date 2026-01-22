#!/bin/sh
# srcs/requirements/bonus/portainer/tools/setup.sh

set -e

if [ ! -f /opt/portainer/portainer ]; then
	echo "[ERRO] Binario do Portainer nao encontrado!"
	exit 1
fi

echo "[INFO] Portainer binario encontrado"
echo "[INFO] Dados armazenados em: /data"

if [ -S /var/run/docker.sock ]; then
	echo "[INFO] Docker socket disponivel"
else
	echo "[AVISO] Docker socket nao encontrado - funcionalidade limitada"
fi

echo "[INFO] Iniciando Portainer na porta 9000..."

exec /opt/portainer/portainer --bind=":9000" --data=/data --no-analytics
