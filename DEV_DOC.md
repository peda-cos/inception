# Inception - Developer Documentation

This document provides technical details, architectural decisions, and workflows for developers maintaining or extending the Inception project.

## 🛠 Development Environment

### Prerequisites

- **OS**: Linux (Virtual Machine recommended)
- **Engine**: Docker Engine 20.10+
- **Orchestrator**: Docker Compose v2.0+
- **Build Tool**: Make
- **Resources**: Minimum 2GB RAM, 2 vCPUs, 20GB Disk

### Directory Structure

```
inception/
├── Makefile                # Build orchestration
├── docker-compose.yml      # Service definitions
├── secrets/                # Secret files (passwords)
└── srcs/requirements/      # Service configurations
    ├── nginx/
    ├── mariadb/
    ├── wordpress/
    └── bonus/              # Bonus services (redis, ftp, etc.)
```

## 🏗 Build Architecture

### Docker Strategy

- **Base Image**: Debian Oldstable (Buster/Bullseye) used strictly to adhere to "penultimate version" requirements.
- **Layer Caching**: Dockerfiles are optimized to copy configuration files _after_ package installation to maximize cache hits.
- **Init Systems**: Custom shell scripts (`init.sh`) handle runtime configuration, avoiding hardcoded config files where dynamic values (env vars) are needed.

### Service Details

#### 1. NGINX (Reverse Proxy)

- **TLS**: Enforced TLS v1.2/v1.3 only.
- **Certificates**: Self-signed, generated at build time via `openssl`.
- **Config**: Located in `srcs/requirements/nginx/conf/`.
- **Logic**: Offloads SSL termination, routes traffic to WordPress (FastCGI) or Static Site (HTTP).

#### 2. MariaDB (Database)

- **Initialization**:
  - Checks if database exists in volume.
  - If not, runs `mysqld_safe` to execute SQL commands from `init.sh` (create DB, User, Root password).
- **Security**: Root login disabled remotely. Bound to `0.0.0.0` for internal network access only.

#### 3. WordPress (CMS)

- **CLI**: Uses `wp-cli` for automated setup (no GUI wizard required).
- **PHP-FPM**: Configured to listen on port 9000.
- **Plugins**: Redis Object Cache installed and activated automatically.
- **Users**: Admin and Editor users created programmatically via secrets.

#### 4. Bonus Services

- **Redis**: Configured with `maxmemory` eviction policies for efficient caching.
- **FTP (vsftpd)**: Chrooted environment. Passive mode ports configured for container networking.
- **Adminer**: Lightweight PHP DB management tool. Connected to MariaDB container.
- **Static Site**: Simple HTML/CSS portfolio served via NGINX.
- **Portainer**: Docker management UI running via socket mount.

## 🐛 Debugging Guide

### Common Commands

| Action              | Command                                       |
| ------------------- | --------------------------------------------- |
| **View Logs**       | `docker-compose logs -f [service_name]`       |
| **Shell Access**    | `docker exec -it [container_name] /bin/bash`  |
| **Restart Service** | `docker-compose restart [service_name]`       |
| **Rebuild Single**  | `docker-compose up -d --build [service_name]` |
| **Inspect Net**     | `docker network inspect inception`            |

### Database Debugging

Access MariaDB directly from the container:

```bash
docker exec -it mariadb mysql -u root -p
# Enter password from secrets/db_root_password.txt
```

### WordPress Debugging

Enable debug mode in `wp-config.php` (via `srcs/requirements/wordpress/tools/init.sh`):

```php
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
```

Logs will appear in `/var/www/html/wp-content/debug.log`.

## 🧪 Testing Procedures

### 1. Network Isolation

Verify services are on the correct network:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx
```

### 2. Volume Persistence

1. Create a post in WordPress.
2. Run `make down` then `make up`.
3. Verify post still exists.
4. Run `make fclean` then `make up`.
5. Verify post is gone.

### 3. SSL Verification

Check certificate protocols:

```bash
openssl s_client -connect peda-cos.42.fr:443 -tls1_2
openssl s_client -connect peda-cos.42.fr:443 -tls1_3
```

## 📝 Modification Guidelines

### Adding a New Service

1. Create directory `srcs/requirements/bonus/new-service`.
2. Create `Dockerfile` and `tools/init.sh` (if needed).
3. Add service block to `docker-compose.yml`.
4. Define volume in `docker-compose.yml` if persistence is needed.
5. Add `depends_on` if it relies on DB or other services.

### Updating Secrets

1. Stop containers: `make down`.
2. Edit files in `secrets/` directory.
3. Rebuild containers: `make re` (containers read secrets at runtime/startup).

## ⚠️ Known Issues & Solutions

- **"Connection Refused" on Build**: Usually MariaDB initializing slowly. The WordPress `init.sh` contains a loop to wait for MariaDB readiness.
- **502 Bad Gateway**: NGINX cannot talk to PHP-FPM. Check if `wordpress` container is running and port 9000 is exposed.
- **FTP Connection Fails**: Ensure Passive Mode ports (21100-21110) are mapped correctly in `docker-compose.yml`.

## 📌 Project Specifics

- **Domain**: Hardcoded to `peda-cos.42.fr`.
- **Volume Path**: `/home/peda-cos/data/`.
- **Network**: Single bridge network named `inception`.
