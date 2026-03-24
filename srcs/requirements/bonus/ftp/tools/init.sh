#!/bin/bash
set -e

read_secret() {
	local secret_file="$1"
	if [ ! -f "$secret_file" ]; then
		echo "[ERROR] Secret file not found: $secret_file" >&2
		return 1
	fi
	tr -d '\n' < "$secret_file"
}

require_env() {
	local var_name="$1"
	local var_value="${!var_name}"
	if [ -z "$var_value" ]; then
		echo "[ERROR] Required environment variable not set: $var_name" >&2
		exit 1
	fi
}

FTP_PASSWORD=$(read_secret "/run/secrets/ftp_password")

FTP_USER="${FTP_USER:-ftpuser}"

require_env FTP_PASSWORD

echo "[INFO] Configuring FTP user: $FTP_USER"

if ! id "$FTP_USER" > /dev/null 2>&1; then
	useradd -m -d /var/www/html -s /bin/bash "$FTP_USER"
	# First-run only: add user to www-data group and enable group-write access
	# This preserves WordPress's www-data:www-data ownership while allowing FTP uploads
	usermod -aG www-data "$FTP_USER"
	chmod -R g+w /var/www/html
fi

echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

echo "$FTP_USER" > /etc/vsftpd.userlist

mkdir -p /var/log/vsftpd
touch /var/log/vsftpd/vsftpd.log

if [ -n "$DOMAIN_NAME" ]; then
	PASV_IP=$(getent hosts "$DOMAIN_NAME" | awk '{ print $1 }' | head -n1)
	if [ -z "$PASV_IP" ]; then
		echo "[WARN] Could not resolve $DOMAIN_NAME to IP, falling back to 0.0.0.0"
		PASV_IP="0.0.0.0"
	fi
	sed -i "s/pasv_address=.*/pasv_address=$PASV_IP/" /etc/vsftpd.conf
fi

echo "[INFO] Starting vsftpd..."
exec vsftpd /etc/vsftpd.conf
