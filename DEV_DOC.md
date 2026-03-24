# Inception - Developer Documentation

This document describes how a developer can set up the environment from scratch, build and run the project, manage containers and volumes, and understand the technical implementation of each service.

## Prerequisites and Environment Setup

### Required Software

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| Linux (Virtual Machine) | — | Required by 42 Subject |
| Docker Engine | 20.10+ | Container runtime |
| Docker Compose (plugin) | v2.0+ | Service orchestration (`docker compose`, not `docker-compose`) |
| Make | any | Build automation |
| Git | any | Repository management |

Verify your installation:

```bash
docker --version          # Docker Engine version
docker compose version    # Docker Compose v2 plugin
make --version
```

### Minimum Resources

- **RAM**: 4 GB (2 GB minimum, 4 GB recommended)
- **CPU**: 2 vCPUs
- **Disk**: 20 GB free

### Project layout at a glance

```
inception/
├── Makefile
├── srcs/
│   ├── .env
│   ├── docker-compose.yml
│   └── requirements/
│       ├── nginx/       mariadb/       wordpress/
│       └── bonus/
│           ├── redis/   ftp/   adminer/   static-site/   portainer/
/home/peda-cos/secrets/   ← secret files (host, not in git)
/home/peda-cos/data/      ← persistent volumes (created by make)
```

---

## Secrets Setup

Secrets are plain text files stored at `/home/peda-cos/secrets/` on the host. They are mounted into containers at `/run/secrets/` as read-only in-memory files.

**This directory is not tracked by git.** `make` creates it and generates all secret files automatically on first run — no manual setup is required. Existing files are never overwritten (idempotent).

### Auto-generation

The `secrets` target in the Makefile generates 32-character alphanumeric passwords using:

```bash
openssl rand -base64 48 | tr -d '/+=' | head -c 32
```

`tr -d '/+='` strips the base64 characters that could cause shell interpretation problems. The result is a 32-character password containing only `[a-zA-Z0-9]`.

The `credentials.txt` file is generated in the required `KEY=VALUE` format with **distinct passwords** for the admin and subscriber users:

```
WORDPRESS_ADMIN_PASSWORD=<32-char alphanumeric>
WORDPRESS_USER_PASSWORD=<32-char alphanumeric>
```

### Overriding with custom passwords

If you want to use your own passwords, create any or all of the following files **before** running `make`:

```bash
mkdir -p /home/peda-cos/secrets

echo "MyCustomDbPass" > /home/peda-cos/secrets/db_password.txt
echo "MyCustomRootPass" > /home/peda-cos/secrets/db_root_password.txt
echo "MyCustomFtpPass" > /home/peda-cos/secrets/ftp_password.txt
printf 'WORDPRESS_ADMIN_PASSWORD=MyAdminPass\nWORDPRESS_USER_PASSWORD=MyEditorPass\n' \
  > /home/peda-cos/secrets/credentials.txt
```

Any file that already exists will be preserved; only missing files are created.

### File reference

| File | Format | Used by | Purpose |
|------|--------|---------|---------|
| `db_password.txt` | plain text (single line) | mariadb, wordpress | MariaDB user password |
| `db_root_password.txt` | plain text (single line) | mariadb | MariaDB root password |
| `ftp_password.txt` | plain text (single line) | ftp | vsftpd user password |
| `credentials.txt` | key=value (two lines) | wordpress | WordPress admin and editor passwords |

### How secrets are consumed

Init scripts use a `read_secret()` shell function that reads a file path from an environment variable (e.g., `MYSQL_ROOT_PASSWORD_FILE=/run/secrets/db_root_password`) and returns its contents stripped of trailing newlines.

The WordPress `credentials.txt` file uses `grep "^KEY=" | cut -d'=' -f2-` for key-value parsing. The `-f2-` (field 2 onwards) ensures passwords containing `=` characters are read correctly — for example, `cut -d'=' -f2-` on `KEY=Pass=word` returns `Pass=word`. Secret values never appear in environment variables or `docker inspect` output.

---

## Environment Variables (`.env`)

Located at `srcs/.env`. Loaded automatically by the Makefile command `docker compose -f srcs/docker-compose.yml --env-file srcs/.env`.

| Variable | Example Value | Purpose |
|----------|--------------|---------|
| `DOMAIN_NAME` | `peda-cos.42.fr` | Main domain for NGINX and WordPress |
| `MYSQL_ROOT_PASSWORD_FILE` | `/run/secrets/db_root_password` | Path to MariaDB root password secret |
| `MYSQL_DATABASE` | `wordpress` | Database name |
| `MYSQL_USER` | `wpuser` | Database user |
| `MYSQL_PASSWORD_FILE` | `/run/secrets/db_password` | Path to DB password secret |
| `WORDPRESS_DB_HOST` | `mariadb:3306` | MariaDB host and port (service DNS name) |
| `WORDPRESS_DB_NAME` | `wordpress` | WordPress database name |
| `WORDPRESS_DB_USER` | `wpuser` | WordPress database user |
| `WORDPRESS_DB_PASSWORD_FILE` | `/run/secrets/db_password` | Path to DB password secret |
| `WORDPRESS_ADMIN_USER` | `supervisor` | WordPress admin username (must not contain "admin") |
| `WORDPRESS_ADMIN_EMAIL` | `peda-cos@student.42sp.org.br` | WordPress admin email |
| `WORDPRESS_USER` | `editor` | WordPress second user username |
| `WORDPRESS_USER_EMAIL` | `editor@peda-cos.42.fr` | WordPress second user email |
| `WORDPRESS_USER_ROLE` | `subscriber` | WordPress second user role |
| `WORDPRESS_TITLE` | `Inception - peda-cos` | WordPress site title |
| `REDIS_HOST` | `redis` | Redis service DNS name |
| `REDIS_PORT` | `6379` | Redis port |
| `FTP_USER` | `ftpuser` | vsftpd username |

The `*_FILE` convention: variables suffixed with `_FILE` store the path to a secret file rather than the value itself. Init scripts read the file content at runtime.

---

## Build and Launch

The Makefile variable `COMPOSE = docker compose -f srcs/docker-compose.yml --env-file srcs/.env` is used for all Docker Compose commands.

### Makefile targets

| Target | Command | Description |
|--------|---------|-------------|
| `make` (default) | `make all` | Generates missing secrets in `/home/peda-cos/secrets/`, creates `/home/peda-cos/data/{wordpress,mariadb,portainer}`, then runs `docker compose up -d --build` for all 8 services |
| `make secrets` | — | Generates missing secret files only (no build, no compose) |
| `make clean` | — | Runs `docker compose down` — stops and removes containers; **volumes and data are preserved** |
| `make fclean` | — | `clean` + removes volumes (`-v`), stops/removes all containers, runs `docker system prune -a --volumes -f`, **deletes `/home/peda-cos/data/`** |
| `make re` | — | `fclean` followed by `all` — complete clean rebuild from scratch |

### Build flow (first run)

```
make
  └── secrets target: generate /home/peda-cos/secrets/{db_password,db_root_password,ftp_password,credentials}.txt
  └── mkdir /home/peda-cos/data/{wordpress,mariadb,portainer}
  └── docker compose up -d --build
        ├── Build 8 images from Dockerfiles
        ├── Start: redis, mariadb (no dependencies)
        ├── Wait for: mariadb (healthy), redis (healthy)
        ├── Start: wordpress
        │     └── init.sh: download WP 6.9.4, create wp-config.php,
        │                   install WP core, create admin + editor users
        ├── Wait for: wordpress (healthy), redis (healthy)
        ├── Start: nginx, adminer, static-site, portainer
        ├── Wait for: wordpress (healthy)  ← ftp waits for this
        └── Start: ftp
              All services: restart: unless-stopped
```

### Subsequent runs

On restart (data already exists), init scripts detect the existing data:
- **MariaDB**: skips `mysql_install_db`, just starts `mysqld` normally.
- **WordPress**: detects existing `wp-config.php`, skips installation, starts `php-fpm8.2 -F` directly.

---

## Service Architecture

All services use `FROM debian:bookworm` as base image.

### NGINX

- **Packages**: `nginx`, `openssl`, `curl`, `procps`
- **SSL**: Generated at **build time** via `tools/setup-ssl.sh` — self-signed RSA 2048-bit X.509 cert + 2048-bit DH parameters. Certificate SAN includes all subdomains.
- **Config**: `conf/nginx.conf` — 4 server blocks on port 443, all TLSv1.2/TLSv1.3.
  - `peda-cos.42.fr` → FastCGI to `wordpress:9000`
  - `adminer.peda-cos.42.fr` → reverse proxy to `adminer:8080`
  - `static.peda-cos.42.fr` → reverse proxy to `static-site:8081`
  - `portainer.peda-cos.42.fr` → reverse proxy to `portainer:9000` (WebSocket)
- **CMD**: `nginx -g "daemon off;"` (no entrypoint script)
- **Exposed port**: 443

### MariaDB

- **Packages**: `mariadb-server`, `mariadb-client`, `procps`
- **Config**: `conf/50-server.cnf` — binds to `0.0.0.0:3306`, UTF8MB4, InnoDB settings
- **Initialization** (`tools/init.sh`):
  1. Reads secrets from `/run/secrets/db_root_password` and `/run/secrets/db_password`
  2. **First run** (no `/var/lib/mysql/mysql`): runs `mysql_install_db --user=mysql`, starts `mysqld --user=mysql --skip-networking`, sets root password, creates database and user with `GRANT ALL PRIVILEGES`, shuts down
  3. **Restart** (data exists): briefly starts with `--skip-networking` to verify/create database if missing
  4. Exec: `mysqld --user=mysql --datadir=/var/lib/mysql`
- **Exposed port**: 3306 (internal only)

### WordPress + PHP-FPM

- **Packages**: `php8.2-fpm`, `php8.2-mysql`, `php8.2-redis`, and various PHP extensions, plus `wp-cli`
- **PHP-FPM config**: `conf/www.conf` — listens on `0.0.0.0:9000`, dynamic process manager, OPcache enabled
- **Initialization** (`tools/init.sh`):
  1. Reads DB password from secret; reads admin/editor passwords from `credentials` secret (key=value format, parsed via `cut -d'=' -f2-` to handle passwords containing `=`)
  2. Validates admin username does not contain "admin" (rejects with error if it does)
  3. Waits for MariaDB readiness (up to 60 attempts × 2s)
   4. **First run** (no `wp-config.php`): downloads WordPress 6.9.4, creates `wp-config.php` via WP-CLI, configures Redis cache settings, installs WordPress core, creates admin user, checks if subscriber user exists before creating (avoids silent error suppression)
  5. **Restart**: skips initialization
  6. Exec: `php-fpm8.2 -F`
- **Exposed port**: 9000 (internal only)

### Redis (Bonus)

- **Packages**: `redis-server`, `procps`
- **Config**: `conf/redis.conf` — binds `0.0.0.0:6379`, pure in-memory mode (`save ""`, `appendonly no`), 128 MB `maxmemory` with `allkeys-lru` eviction
- **Entrypoint**: `exec redis-server /etc/redis/redis.conf`
- **Exposed port**: 6379 (internal only)

### FTP — vsftpd (Bonus)

- **Packages**: `vsftpd`, `procps`
- **Config**: `conf/vsftpd.conf` — local users, no anonymous, chroot, passive mode ports 21100–21110
- **Initialization** (`tools/init.sh`): reads FTP password from secret, creates system user with home `/var/www/html`, sets password, writes vsftpd userlist, sets `pasv_address` dynamically from `DOMAIN_NAME`
- **Exec**: `vsftpd /etc/vsftpd.conf`
- **Exposed ports**: 21, 21100–21110 (host)

### Adminer (Bonus)

- **Packages**: `php8.2-cli`, `php8.2-mysql`, `php8.2-mbstring`, `curl`
- **Downloads**: Adminer v5.4.2 PHP file + Nette CSS theme (pinned to v5.4.2)
- **Runtime**: PHP built-in server `php -S 0.0.0.0:8080 -t /var/www/html`
- **Exposed port**: 8080 (internal only, proxied via NGINX)

### Static Site (Bonus)

- **Packages**: `nginx`, `curl`, `procps`
- **Content**: Portfolio site (`www/index.html`, `www/style.css`) served from `/var/www/static/`
- **Config**: `conf/nginx.conf` — listens on port 8081
- **CMD**: `nginx -g "daemon off;"`
- **Exposed port**: 8081 (internal only, proxied via NGINX)

### Portainer (Bonus)

- **Downloads**: Portainer CE v2.39.1 binary to `/opt/portainer/portainer`
- **Mounts**: Docker socket (`/var/run/docker.sock:ro`) and `portainer_data:/data`
- **Entrypoint** (`tools/setup.sh`): validates binary and socket, then `exec /opt/portainer/portainer --bind=":9000" --data=/data --no-analytics`
- **Exposed port**: 9000 (internal only, proxied via NGINX at `portainer.peda-cos.42.fr`)

---

## Container and Volume Management

### Full compose command prefix

```bash
COMPOSE="docker compose -f srcs/docker-compose.yml --env-file srcs/.env"
```

Or use Make targets which include this automatically.

### Useful commands

| Action | Command |
|--------|---------|
| View all container status | `docker compose -f srcs/docker-compose.yml ps` |
| Follow all logs | `docker compose -f srcs/docker-compose.yml logs -f` |
| Follow logs for one service | `docker compose -f srcs/docker-compose.yml logs -f nginx` |
| Open shell in a container | `docker exec -it nginx /bin/bash` |
| Restart a single service | `docker compose -f srcs/docker-compose.yml restart wordpress` |
| Rebuild and restart one service | `docker compose -f srcs/docker-compose.yml up -d --build wordpress` |
| Inspect the Docker network | `docker network inspect inception` |
| List volumes | `docker volume ls` |
| Inspect a volume | `docker volume inspect wordpress_data` |

### Data storage and persistence

| Volume | Host Path | Mounted by | Contents |
|--------|-----------|-----------|---------|
| `wordpress_data` | `/home/peda-cos/data/wordpress` | wordpress (rw), nginx (ro), ftp (rw) | WordPress core files, themes, plugins, uploads |
| `db_data` | `/home/peda-cos/data/mariadb` | mariadb (rw) | MariaDB database files |
| `portainer_data` | `/home/peda-cos/data/portainer` | portainer (rw) | Portainer configuration |

Volumes use the `local` driver with `o: bind`, meaning Docker manages them as named volumes while data is actually stored at the host paths above.

**Persistence behavior:**

- `make clean` (`docker compose down`) — containers stop, volumes and host data remain intact. `make` will restart containers with existing data (no re-initialization).
- `make fclean` — removes all containers, images, volumes, and **deletes `/home/peda-cos/data/`**. The next `make` will initialize everything from scratch.

---

## Debugging and Testing

### Database access

```bash
# Connect to MariaDB as the WordPress user
docker exec -it mariadb mysql -u wpuser -p wordpress
# Password: contents of secrets/db_password.txt

# Connect as root
docker exec -it mariadb mysql -u root -p
# Password: contents of secrets/db_root_password.txt
```

### WP-CLI (WordPress CLI)

```bash
# List WordPress users
docker exec -it wordpress wp user list --allow-root

# Check WordPress status
docker exec -it wordpress wp core version --allow-root

# Flush Redis cache
docker exec -it wordpress wp cache flush --allow-root
```

### SSL verification

```bash
# Verify TLS 1.2 works
openssl s_client -connect peda-cos.42.fr:443 -tls1_2

# Verify TLS 1.3 works
openssl s_client -connect peda-cos.42.fr:443 -tls1_3

# View certificate details
openssl s_client -connect peda-cos.42.fr:443 < /dev/null 2>/dev/null | openssl x509 -noout -text
```

### Network isolation

```bash
# Get the IP of a container inside the inception network
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx

# Verify DNS resolution inside a container (containers must resolve each other by name)
docker exec -it nginx getent hosts wordpress
docker exec -it wordpress getent hosts mariadb
docker exec -it wordpress getent hosts redis
```

### Volume persistence test

1. Create a post in WordPress at `https://peda-cos.42.fr/wp-admin`.
2. Run `make clean` (stops containers).
3. Run `make` (restarts containers — no rebuild needed).
4. Verify the post still exists.
5. Run `make fclean` then `make` — the post should be gone (full reset).

### Container health status

```bash
# View health status of all containers
docker compose -f srcs/docker-compose.yml ps

# View health check logs for a container
docker inspect --format='{{json .State.Health}}' wordpress | python3 -m json.tool
```

### Common issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `docker compose up` fails with "no such file: /home/peda-cos/secrets/..."  | Secret files not generated yet | Run `make secrets` or simply `make` which auto-generates them |
| WordPress container unhealthy | MariaDB not ready yet | Wait for MariaDB to become healthy; check `docker compose logs mariadb` |
| `502 Bad Gateway` from NGINX | WordPress PHP-FPM not running | Check `docker compose logs wordpress`; verify port 9000 |
| FTP connection refused | Passive mode not set in client | Enable passive mode in FTP client; check ports 21100–21110 are mapped |
| `Access denied` in MariaDB | Wrong password in secret file | Verify `secrets/db_password.txt` matches what was used at initialization |
| WordPress shows "Error establishing a database connection" | MariaDB still initializing | Run `docker compose logs mariadb` and wait for "Starting MariaDB..." |

### Adding a new bonus service

1. Create `srcs/requirements/bonus/<service-name>/Dockerfile` (use `debian:bookworm` as base).
2. Add entrypoint script at `srcs/requirements/bonus/<service-name>/tools/init.sh` if needed.
3. Add a service block to `srcs/docker-compose.yml` with `restart: unless-stopped`, `networks: [inception]`, and a `healthcheck`.
4. If the service needs external access, add `ports:` mapping and configure an NGINX reverse proxy server block.
5. If persistence is needed, add a named volume with `driver: local` and `driver_opts: {type: none, o: bind, device: /home/peda-cos/data/<service-name>}`.
6. Update the `DATA_PATH` directory creation in the `Makefile` `all` target.
