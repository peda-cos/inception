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
	local var_value
	eval "var_value=\$$var_name"
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
fi

echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

chown -R "$FTP_USER":www-data /var/www/html
chmod -R 775 /var/www/html

echo "$FTP_USER" > /etc/vsftpd.userlist

mkdir -p /var/log/vsftpd
touch /var/log/vsftpd/vsftpd.log

if [ -n "$DOMAIN_NAME" ]; then
	sed -i "s/pasv_address=.*/pasv_address=$DOMAIN_NAME/" /etc/vsftpd.conf
fi

echo "[INFO] Starting vsftpd..."
exec vsftpd /etc/vsftpd.conf
