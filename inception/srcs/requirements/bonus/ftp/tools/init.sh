#!/bin/bash
set -e

read_secret() {
	local secret_file="$1"
	if [ -f "$secret_file"]; then
		cat "$secret_file" | tr -d '\n'
	else
		echo ""
	fi
}

FTP_PASSWORD=$(read_secret "/run/secrets/ftp_password")

FTP_USER="${FTP_USER:-ftpuser}"

echo "[INFO] Configurando usuario FTP: $FTP_USER"

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
	sed -i "s/pasv_address=.*/pasv_address=$DOMAIN_NAME/" /etc/vsftpd.co
fi

echo "[INFO] Iniciando vsftpd..."
exec vsftpd /etc/vsftpd.conf
