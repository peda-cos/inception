*This project has been created as part of the 42 curriculum by peda-cos*

# Inception

## Description

Inception is a 42 School system administration project that broadens knowledge of Docker by building a complete multi-container infrastructure inside a virtual machine. The goal is to design, configure, and orchestrate several services using custom-built Docker images — no pre-built images allowed.

The infrastructure is composed of **8 services**, split into mandatory and bonus:

| # | Service | Role | Type |
|---|---------|------|------|
| 1 | **NGINX** | HTTPS reverse proxy and only entry point (port 443, TLSv1.2/1.3) | Mandatory |
| 2 | **WordPress + PHP-FPM** | Content Management System with FastCGI processor | Mandatory |
| 3 | **MariaDB** | Relational database for WordPress | Mandatory |
| 4 | **Redis** | In-memory object cache for WordPress | Bonus |
| 5 | **FTP (vsftpd)** | File transfer access to the WordPress volume | Bonus |
| 6 | **Adminer** | Web-based database management interface | Bonus |
| 7 | **Static Site** | Personal portfolio page served by its own NGINX instance | Bonus |
| 8 | **Portainer** | Docker container management and monitoring UI | Bonus |

All images are built from `debian:bookworm` using custom `Dockerfile`s. Passwords and credentials are managed through Docker secrets; non-sensitive configuration is handled via environment variables.

## Instructions

### Prerequisites

- **Virtual Machine** running Linux (recommended: Debian or Ubuntu)
- **Docker Engine** 20.10 or later
- **Docker Compose** v2.0 or later (`docker compose` plugin, not `docker-compose`)
- **Make**
- Minimum resources: 2 vCPUs, 4 GB RAM, 20 GB disk

### 1. Clone the repository

```bash
git clone <repository-url> inception
cd inception
```

### 2. Configure domain resolution

Add the following line to `/etc/hosts` on the host machine (replace `127.0.0.1` with your VM's IP if accessing from outside):

```bash
sudo nano /etc/hosts
```

Add:

```
127.0.0.1   peda-cos.42.fr www.peda-cos.42.fr adminer.peda-cos.42.fr static.peda-cos.42.fr portainer.peda-cos.42.fr
```

### 3. Secrets (auto-generated)

Passwords for the database, WordPress users, and FTP are stored as plain text files in `/home/peda-cos/secrets/` on the host. This directory is **not** tracked by git.

**`make` generates all secret files automatically** the first time it runs — no manual setup required. If the files already exist they are preserved (idempotent). Secrets are generated using `openssl rand`, producing 32-character alphanumeric passwords.

If you want to use custom passwords instead, create any or all of the following files before running `make`:

```bash
mkdir -p /home/peda-cos/secrets

# (optional) override any of these — omit to let make generate them
echo "MyCustomDbPass" > /home/peda-cos/secrets/db_password.txt
echo "MyCustomRootPass" > /home/peda-cos/secrets/db_root_password.txt
echo "MyCustomFtpPass" > /home/peda-cos/secrets/ftp_password.txt
printf 'WORDPRESS_ADMIN_PASSWORD=MyAdminPass\nWORDPRESS_USER_PASSWORD=MyEditorPass\n' \
  > /home/peda-cos/secrets/credentials.txt
```

> **Security**: Never commit the `secrets/` directory or any file containing passwords to version control.

### 4. Build and start

From the project root:

```bash
make
```

This will:
1. Generate any missing secret files in `/home/peda-cos/secrets/` (idempotent)
2. Create the data directories at `/home/peda-cos/data/`
3. Build all Docker images from the `Dockerfile`s
4. Start all 8 containers in the correct dependency order
5. Initialize WordPress, MariaDB, and Redis on first run

**First build takes 5–10 minutes** depending on internet speed.

### 5. Verify

```bash
docker compose -f srcs/docker-compose.yml ps
```

All services should show `Up` with status `(healthy)`.

### Available Makefile targets

| Target | Description |
|--------|-------------|
| `make` | Build all images and start all containers |
| `make clean` | Stop all containers (data is preserved) |
| `make fclean` | Stop containers, remove all images/volumes, delete `/home/peda-cos/data/` |
| `make re` | Full clean rebuild (`fclean` + `make`) |

## Resources

### Documentation

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [NGINX `fastcgi_pass` Module](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html)
- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [WordPress CLI (WP-CLI)](https://wp-cli.org/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [vsftpd Manual](https://security.appspot.com/vsftpd/vsftpd_conf.html)
- [Redis Configuration](https://redis.io/docs/management/config/)
- [Adminer](https://www.adminer.org/)
- [Portainer Documentation](https://docs.portainer.io/)
- [OpenSSL Self-Signed Certificates](https://www.openssl.org/docs/manmaster/man1/req.html)
- [PID 1 in Docker Containers](https://cloud.google.com/architecture/best-practices-for-building-containers#signal-handling)

### AI Usage

This project was developed with assistance from **Claude Code** (Anthropic) for:

- **Configuration generation**: NGINX `nginx.conf` (server blocks, TLS settings, FastCGI parameters), PHP-FPM `www.conf` (pool settings, OPcache), MariaDB `50-server.cnf` (InnoDB tuning, character set), Redis `redis.conf` (memory limits, eviction policy).
- **Entrypoint scripts**: Logic for first-run detection, secret reading from `/run/secrets/`, MariaDB initialization flow, WordPress installation via WP-CLI.
- **Debugging**: Diagnosing container dependency ordering, healthcheck failures, and FTP passive mode configuration.
- **Documentation**: Structure and content for README.md, DEV_DOC.md, and USER_DOC.md.

All code was written and tested by the project author. AI assistance was used as a productivity and learning tool to accelerate development and ensure alignment with best practices.

## Project description

This section explains the technical choices made in the project, with comparisons between the approached alternatives.

### Virtual Machines vs Docker

**Virtual Machines (VMs)**:
- Run a complete guest operating system, including a dedicated kernel, on top of a hypervisor (e.g., VirtualBox, VMware, KVM).
- Provide strong hardware-level isolation.
- High resource overhead: each VM requires several GB of RAM and a full OS installation.
- Slow boot times (minutes), extensive maintenance (OS patching per VM).

**Docker Containers**:
- Share the host OS kernel; each container is an isolated process using Linux namespaces and cgroups.
- Lightweight: containers start in seconds and use only the packages they need.
- Near-native performance with minimal overhead.
- Portable: the same image runs identically on any Docker host.

**Project choice**: Docker containers are used for all services. Each service runs in its own container with a single responsibility, providing isolation without the cost of full VMs. The project itself runs inside a VM as required by the 42 Subject.

---

### Secrets vs Environment Variables

**Environment Variables**:
- Passed to containers via `.env` files or the `environment:` key in `docker-compose.yml`.
- Visible in `docker inspect`, container process listings, and logs.
- Suitable for non-sensitive configuration: domain names, ports, usernames, database names.

**Docker Secrets**:
- Stored as files on the host and mounted into containers at `/run/secrets/` as read-only, in-memory tmpfs.
- Never appear in `docker inspect`, environment variable listings, or process tables.
- Automatically removed from the container filesystem when the container stops.
- Suitable for sensitive data: passwords, API keys, tokens.

**Project choice**: Docker secrets are used for all passwords (`db_password.txt`, `db_root_password.txt`, `ftp_password.txt`, `credentials.txt`). Environment variables (in `srcs/.env`) are used for non-sensitive values such as `DOMAIN_NAME`, `MYSQL_USER`, and `WORDPRESS_ADMIN_USER`. Container init scripts reference secret file paths via `*_FILE` environment variables, never the values directly.

---

### Docker Network vs Host Network

**Host Network** (`network_mode: host`):
- The container shares the host's network stack directly — no isolation.
- All host ports are accessible to the container, and vice versa.
- Risk of port conflicts between services.
- The `--link` flag and `links:` key are legacy mechanisms with similar isolation drawbacks.

**Docker Bridge Network** (custom):
- Creates an isolated virtual network for the containers.
- Containers communicate by service name (Docker's built-in DNS resolution): `wordpress` resolves to the WordPress container's IP.
- External access requires explicit port mapping (`ports:` in `docker-compose.yml`).
- Full network isolation from the host and other Docker networks.

**Project choice**: A custom bridge network named `inception` is used. All 8 services are attached to it. Only NGINX (port 443) and FTP (ports 21, 21100–21110) expose ports to the host. All inter-service communication is internal only (e.g., `wordpress → mariadb:3306`, `nginx → wordpress:9000`). Using `network: host`, `--link`, or `links:` is explicitly prohibited by the Subject.

---

### Docker Volumes vs Bind Mounts

**Bind Mounts**:
- Map a specific host directory path directly into the container.
- Changes on the host are immediately reflected inside the container.
- Depend on the host directory structure; not portable.
- No Docker management (no `docker volume ls`, no Docker-managed backup).

**Docker Volumes**:
- Managed by Docker, stored at `/var/lib/docker/volumes/` by default.
- Can be shared between multiple containers.
- Docker handles lifecycle (create, inspect, remove).
- Portable and not tied to host paths.

**Project choice**: Named volumes with the `local` driver and `bind` mount type are used. This combines Docker volume semantics (named volumes appear in `docker volume ls`, proper `depends_on` handling) with bind mount behavior (data stored at known host paths: `/home/peda-cos/data/`). This allows easy host-level backup while maintaining Docker's volume management.

| Volume | Host Path | Containers |
|--------|-----------|------------|
| `wordpress_data` | `/home/peda-cos/data/wordpress` | wordpress (rw), nginx (ro), ftp (rw) |
| `db_data` | `/home/peda-cos/data/mariadb` | mariadb (rw) |
| `portainer_data` | `/home/peda-cos/data/portainer` | portainer (rw) |

## Architecture

### Service diagram

```
Host machine (port 443)  ──→  nginx (TLS termination)
                                ├──→ wordpress:9000  (FastCGI)
                                │       └──→ mariadb:3306
                                │       └──→ redis:6379
                                ├──→ adminer:8080    (HTTP proxy)
                                ├──→ static-site:8081 (HTTP proxy)
                                └──→ portainer:9000  (HTTP proxy + WebSocket)

Host machine (port 21)   ──→  ftp (vsftpd → wordpress volume)
```

### Network: `inception` (bridge)

All containers are on the `inception` custom bridge network. DNS-based service discovery is used throughout (e.g., `wordpress` resolves to the WordPress container).

### Initialization order

```
MariaDB ─(healthy)─→ WordPress ─(healthy)─→ NGINX
Redis   ─(healthy)─→ WordPress
Redis   ─(healthy)─→ NGINX
MariaDB ──────────→ Adminer
WordPress ─(healthy)─→ FTP
NGINX ────────────→ Portainer
```

### Base image

All `Dockerfile`s use `debian:bookworm` (Debian 12, the penultimate stable version). The Subject requires "the penultimate stable version of Alpine or Debian." With Debian 13 (Trixie) released as the current stable in mid-2025, Debian `bookworm` is the correct penultimate choice.

### Container design principles

- **One service per container**: each container runs exactly one process as PID 1.
- **No `latest` tags**: all versions are explicitly pinned.
- **No passwords in `Dockerfile`s**: all secrets come from Docker secrets at runtime.
- **Graceful PID 1**: all entrypoint scripts use `exec` to replace the shell, so the service process receives signals directly (SIGTERM for graceful shutdown).
- **Healthchecks**: every service has a `HEALTHCHECK` instruction in its `Dockerfile` and a `healthcheck:` block in `docker-compose.yml`.
- **Restart policy**: `restart: unless-stopped` on all services.

## Project Structure

```
inception/
├── Makefile                          # Build, start, clean, rebuild
├── README.md
├── DEV_DOC.md
├── USER_DOC.md
└── srcs/
    ├── .env                          # Non-sensitive environment variables
    ├── docker-compose.yml            # Service orchestration
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/nginx.conf       # NGINX server blocks (4 virtual hosts)
        │   └── tools/setup-ssl.sh   # Self-signed cert generation (build-time)
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/www.conf         # PHP-FPM pool configuration
        │   └── tools/init.sh         # WordPress installation via WP-CLI
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/50-server.cnf    # MariaDB server configuration
        │   └── tools/init.sh         # Database initialization
        ├── tools/                    # Shared tools directory (subject requirement)
        └── bonus/
            ├── redis/
            │   ├── Dockerfile
            │   ├── conf/redis.conf
            │   └── tools/init.sh
            ├── ftp/
            │   ├── Dockerfile
            │   ├── conf/vsftpd.conf
            │   └── tools/init.sh
            ├── adminer/
            │   └── Dockerfile
            ├── static-site/
            │   ├── Dockerfile
            │   ├── conf/nginx.conf
            │   └── www/              # Portfolio HTML + CSS
            └── portainer/
                ├── Dockerfile
                └── tools/setup.sh

secrets/                              # Secret files (NOT in git, generated by make)
    ├── db_password.txt
    ├── db_root_password.txt
    ├── ftp_password.txt
    └── credentials.txt

/home/peda-cos/data/                  # Persistent data (created by make)
    ├── wordpress/
    ├── mariadb/
    └── portainer/
```

## 42 Subject Compliance

| Requirement | Status | Notes |
|-------------|--------|-------|
| TLSv1.2 or TLSv1.3 only on NGINX | ✅ | `ssl_protocols TLSv1.2 TLSv1.3` |
| NGINX is the only entry point (port 443) | ✅ | Only HTTPS port exposed (plus FTP and Portainer for bonus) |
| WordPress + PHP-FPM without NGINX in same container | ✅ | Separate containers |
| MariaDB without NGINX in same container | ✅ | Separate container |
| Two volumes: WordPress files and database | ✅ | `wordpress_data`, `db_data` |
| Custom Docker network | ✅ | `inception` bridge network |
| Containers restart on crash | ✅ | `restart: unless-stopped` |
| No `latest` tag | ✅ | All images pinned (e.g., `debian:bookworm`) |
| No passwords in `Dockerfile`s | ✅ | All credentials via Docker secrets |
| Environment variables used | ✅ | `srcs/.env` |
| `.env` file used | ✅ | `srcs/.env` |
| Admin username does not contain "admin" | ✅ | Username: `supervisor` (validated in `init.sh`) |
| Domain `peda-cos.42.fr` points to local IP | ✅ | Via `/etc/hosts` |
| One service per container | ✅ | Each `Dockerfile` runs one process |
| `Dockerfile`s called from `docker-compose.yml` via `Makefile` | ✅ | |
| No `network: host`, `--link`, or `links:` | ✅ | Custom bridge network used |
| No hacky infinite loop commands | ✅ | All services use `exec` to run the process directly |
