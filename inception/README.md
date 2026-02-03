# Inception - Docker Infrastructure Project

42 School project implementing a complete multi-container infrastructure using Docker and Docker Compose.

## Architecture Overview

This project demonstrates infrastructure virtualization using Docker containers orchestrated by Docker Compose. The architecture follows a microservices pattern with isolated, single-responsibility services communicating through a custom Docker network.

### Why Docker vs Virtual Machines?

**Virtual Machines** run complete operating systems with dedicated kernels, requiring significant overhead (memory, CPU, storage). Each VM includes a full OS stack.

**Docker Containers** share the host OS kernel, running isolated processes with minimal overhead. Containers are:

- **Lightweight**: Start in seconds, use minimal resources
- **Portable**: Consistent behavior across environments
- **Isolated**: Each container runs independently
- **Efficient**: Share common layers, optimize storage

### Services Architecture

#### Mandatory Services

1. **NGINX** (Port 443)
   - TLS 1.3 termination with self-signed certificates
   - Reverse proxy for WordPress and bonus services
   - Serves static content

2. **MariaDB** (Port 3306, internal)
   - Relational database for WordPress
   - Persistent data via Docker volumes
   - Custom configuration for optimization

3. **WordPress + PHP-FPM** (Port 9000, internal)
   - Content management system
   - PHP-FPM for FastCGI processing
   - WP-CLI for automation

#### Bonus Services

4. **Redis** (Port 6379, internal)
   - Object caching for WordPress
   - In-memory key-value store

5. **FTP (vsftpd)** (Ports 21, 21100-21110)
   - File transfer to WordPress volume
   - Passive mode for firewall compatibility

6. **Adminer** (Port 8080, proxied)
   - Web-based database management
   - Alternative to phpMyAdmin

7. **Static Site** (Port 80, proxied)
   - Portfolio/landing page
   - Served directly by NGINX

8. **Portainer** (Port 9000, exposed)
   - Docker management UI
   - Container monitoring and control

## Security Architecture

### Secrets vs Environment Variables

**Environment Variables** (`.env` file):

- Non-sensitive configuration (hostnames, ports, usernames)
- Visible in container inspect, logs, and process lists
- Used for: `DOMAIN_NAME`, `MYSQL_USER`, `WORDPRESS_ADMIN_USER`

**Docker Secrets** (`secrets/` directory):

- Sensitive credentials (passwords, tokens)
- Mounted as in-memory files at `/run/secrets/`
- Never logged or exposed in container metadata
- Used for: Database passwords, FTP passwords, admin credentials

**Security Benefits**:

- Secrets aren't committed to version control (`.gitignore`)
- Secrets aren't visible in `docker inspect` output
- Secrets are mounted read-only with restricted permissions
- Secrets are removed when container stops

### TLS/SSL Implementation

- Self-signed X.509 certificates generated during build
- TLS 1.3 with modern cipher suites
- Subject Alternative Names (SAN) for all subdomains
- 2048-bit RSA keys + Diffie-Hellman parameters

## Network Architecture

### Custom Bridge Network: `inception-network`

All services communicate through an isolated Docker bridge network providing:

**DNS Resolution**: Containers resolve each other by service name

```
wordpress -> mariadb:3306  # Instead of IP addresses
```

**Isolation**: Services aren't accessible from host except exposed ports

**Service Discovery**: Automatic DNS entries for all containers

### Port Mapping Strategy

**Exposed Ports** (accessible from host):

- `443` → NGINX (HTTPS)
- `9000` → Portainer (Management UI)

**Internal Ports** (network-only):

- `3306` → MariaDB
- `9000` → WordPress PHP-FPM
- `6379` → Redis
- `8080` → Adminer (proxied via NGINX)
- `8081` → Static Site (proxied via NGINX)
- `21`, `21100-21110` → FTP

## Volume Architecture

### Persistent Data Storage

Docker volumes provide data persistence independent of container lifecycle:

1. **WordPress Data** (`/home/peda-cos/data/wordpress`)
   - WordPress files, themes, plugins, uploads
   - Shared between WordPress and FTP containers
   - Bind mount for direct host access

2. **Database Data** (`/home/peda-cos/data/mariadb`)
   - MariaDB database files
   - Persists across container restarts/rebuilds
   - Bind mount for backup accessibility

### Volume Benefits

- **Persistence**: Data survives container removal
- **Performance**: Direct kernel I/O, no abstraction
- **Backups**: Easy host-level backup/restore
- **Sharing**: Multiple containers can mount same volume

## Container Images

All images built `FROM debian:oldstable` ensuring:

- Stability (penultimate version requirement)
- Security updates
- Consistent base across services
- Small attack surface

### Version Pinning Strategy

**Explicit Versions** (penultimate stable):

- WordPress: `6.7.x`
- Adminer: `5.4.0`
- Portainer: `2.33.5`

**Debian Packages** (oldstable repository):

- NGINX: Latest in `oldstable`
- MariaDB: Latest in `oldstable`
- PHP: `8.2.x` from `oldstable`
- Redis: Latest in `oldstable`

## Build and Initialization

### Container Initialization Scripts

Each service includes entrypoint scripts handling:

- Secret reading from `/run/secrets/`
- First-run initialization vs restart detection
- Health checks and dependency waiting
- Graceful shutdown (PID 1 signal handling)

### Initialization Order

Docker Compose handles dependency order via `depends_on`:

```
MariaDB → WordPress → NGINX
```

Services wait for dependencies using health checks and connection retries.

## Project Structure

```
inception/
├── Makefile                 # Build, start, stop, clean commands
├── secrets/                 # Docker secrets (not in git)
│   ├── db_root_password.txt
│   ├── db_password.txt
│   ├── ftp_password.txt
│   └── credentials.txt
└── srcs/
    ├── .env                 # Environment configuration
    ├── docker-compose.yml   # Service orchestration
    └── requirements/
        ├── nginx/           # Web server + TLS
        ├── mariadb/         # Database
        ├── wordpress/       # CMS + PHP-FPM
        └── bonus/
            ├── redis/       # Cache
            ├── ftp/         # File transfer
            ├── adminer/     # DB admin
            ├── static-site/ # Portfolio
            └── portainer/   # Container management
```

## Key Design Decisions

1. **Single-Process Containers**: Each container runs one service (PID 1)
2. **No Latest Tags**: All versions explicitly pinned
3. **Health Checks**: Every service includes health check logic
4. **Graceful Shutdown**: Proper signal handling (SIGTERM → SIGKILL)
5. **Read-Only Secrets**: Mounted as in-memory files
6. **Custom Network**: Isolated bridge network for inter-service communication
7. **Bind Mounts**: Persistent volumes at `/home/peda-cos/data/`

## Compliance Notes

**42 Subject Requirements**:

- ✅ TLS 1.3 only (NGINX)
- ✅ Two volumes (WordPress, MariaDB)
- ✅ Custom Docker network
- ✅ Containers restart on crash
- ✅ No `latest` tags
- ✅ Penultimate stable versions
- ✅ Domain: `peda-cos.42.fr` (via `/etc/hosts`)
- ✅ Admin username doesn't contain "admin"
- ✅ Dockerfiles in dedicated folders
- ✅ One service per container

## References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [WordPress Codex](https://codex.wordpress.org/)
