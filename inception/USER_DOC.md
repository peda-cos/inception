# User Documentation - Inception Project

Complete guide for using and accessing the Inception infrastructure.

## Prerequisites

- Linux or macOS system with Docker and Docker Compose installed
- Administrative access (for editing `/etc/hosts`)
- At least 4GB free RAM
- 10GB free disk space

## Initial Setup

### 1. Configure Domain Resolution

Add the following line to your `/etc/hosts` file:

```bash
sudo nano /etc/hosts
```

Add:

```
127.0.0.1   peda-cos.42.fr www.peda-cos.42.fr adminer.peda-cos.42.fr static.peda-cos.42.fr portainer.peda-cos.42.fr
```

### 2. Build and Start Services

Navigate to project root and run:

```bash
make
```

This will:

1. Create necessary data directories
2. Build all Docker images
3. Start all containers
4. Initialize databases and services

**First build takes 5-10 minutes** depending on internet speed.

## Accessing Services

Once started, services are available at:

### Primary Services

**WordPress CMS**

- URL: `https://peda-cos.42.fr`
- Admin Panel: `https://peda-cos.42.fr/wp-admin`
- Admin User: `supervisor`
- Admin Password: Check `secrets/credentials.txt` → `WORDPRESS_ADMIN_PASSWORD`
- Editor User: `editor`
- Editor Password: Check `secrets/credentials.txt` → `WORDPRESS_USER_PASSWORD`

**Certificate Warning**: You'll see a browser security warning because we use self-signed certificates. Click "Advanced" → "Proceed to site" (safe for local development).

### Bonus Services

**Adminer (Database Management)**

- URL: `https://adminer.peda-cos.42.fr`
- System: `MySQL`
- Server: `mariadb`
- Username: `wpuser`
- Password: Check `secrets/db_password.txt`
- Database: `wordpress`

**Static Portfolio Site**

- URL: `https://static.peda-cos.42.fr`
- No authentication required

**Portainer (Docker Management)**

- URL: `http://peda-cos.42.fr:9000`
- First Visit: Create admin account
- Then: Login with your credentials

**FTP Server**

- Host: `peda-cos.42.fr`
- Port: `21`
- User: `ftpuser`
- Password: Check `secrets/ftp_password.txt`
- Directory: `/var/www/html` (WordPress files)

**FTP Client Example (FileZilla)**:

```
Host: peda-cos.42.fr
Port: 21
Username: ftpuser
Password: [from secrets/ftp_password.txt]
Transfer Mode: Passive
```

**FTP Client Example (Command Line)**:

```bash
ftp peda-cos.42.fr
# Enter username: ftpuser
# Enter password: [from secrets/ftp_password.txt]
```

## Common Operations

### Start Infrastructure

```bash
make up
```

Or to rebuild images:

```bash
make
```

### Stop Infrastructure

```bash
make down
```

Containers stop but data persists in volumes.

### View Logs

```bash
# All services
make logs

# Specific service
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

### Check Service Status

```bash
docker compose -f srcs/docker-compose.yml ps
```

### Restart Single Service

```bash
docker compose -f srcs/docker-compose.yml restart nginx
```

### Clean Everything

⚠️ **WARNING**: This deletes all data (database, uploads, posts)!

```bash
make fclean
```

Then rebuild:

```bash
make
```

## Using WordPress

### Creating Content

1. Login to admin panel: `https://peda-cos.42.fr/wp-admin`
2. Username: `supervisor`
3. Password: Check `secrets/credentials.txt`

### Installing Themes/Plugins

**Via WordPress UI**:

1. Dashboard → Appearance → Themes → Add New
2. Dashboard → Plugins → Add New

**Via FTP**:

1. Connect via FTP (see FTP section above)
2. Upload to `/var/www/html/wp-content/themes/` (themes)
3. Upload to `/var/www/html/wp-content/plugins/` (plugins)

### Uploading Media

**Via WordPress UI**:

- Media → Add New → Upload files

**Via FTP**:

- Upload to `/var/www/html/wp-content/uploads/`

## Troubleshooting

### Service Won't Start

```bash
# Check logs
make logs

# Check specific service
docker compose -f srcs/docker-compose.yml logs [service-name]
```

### Can't Access Website

1. **Check `/etc/hosts`**:

   ```bash
   cat /etc/hosts | grep peda-cos
   ```

   Should show: `127.0.0.1 peda-cos.42.fr ...`

2. **Check containers are running**:

   ```bash
   docker compose -f srcs/docker-compose.yml ps
   ```

   All should show "Up"

3. **Check NGINX logs**:
   ```bash
   docker compose -f srcs/docker-compose.yml logs nginx
   ```

### Database Connection Error

1. **Wait 30 seconds** - MariaDB takes time to initialize on first run
2. **Check MariaDB logs**:
   ```bash
   docker compose -f srcs/docker-compose.yml logs mariadb
   ```
3. **Restart WordPress**:
   ```bash
   docker compose -f srcs/docker-compose.yml restart wordpress
   ```

### FTP Connection Fails

1. **Passive mode required** - Enable in FTP client settings
2. **Check FTP logs**:
   ```bash
   docker compose -f srcs/docker-compose.yml logs ftp
   ```
3. **Verify password** from `secrets/ftp_password.txt`

### WordPress Slow

Enable Redis cache (already configured):

1. Install Redis Object Cache plugin via WordPress admin
2. Activate plugin
3. Go to Settings → Redis → Enable Object Cache

### Forgot WordPress Password

Reset via WP-CLI:

```bash
docker compose -f srcs/docker-compose.yml exec wordpress wp user update supervisor --user_pass=NewPassword123! --allow-root
```

## Data Backup

### Backup WordPress Files

```bash
tar -czf wordpress-backup-$(date +%Y%m%d).tar.gz /home/peda-cos/data/wordpress
```

### Backup Database

```bash
docker compose -f srcs/docker-compose.yml exec mariadb mysqldump -u root -p$(cat secrets/db_root_password.txt) wordpress > wordpress-db-backup-$(date +%Y%m%d).sql
```

### Restore Database

```bash
cat wordpress-db-backup-YYYYMMDD.sql | docker compose -f srcs/docker-compose.yml exec -T mariadb mysql -u root -p$(cat secrets/db_root_password.txt) wordpress
```

## Performance Monitoring

### Resource Usage

```bash
docker stats
```

Shows real-time CPU, memory, network usage per container.

### Container Health

```bash
docker compose -f srcs/docker-compose.yml ps
```

Check "Status" column - should show "healthy" for all services.

## Security Notes

1. **Secrets Files**: Never commit `secrets/` directory to version control
2. **Self-Signed Certificates**: Only use in development/evaluation
3. **Default Passwords**: Change all passwords in production
4. **FTP Access**: Use SFTP/FTPS in production environments
5. **Admin User**: Default username `supervisor` doesn't contain "admin" (42 requirement)

## Support

For issues:

1. Check logs: `make logs`
2. Verify all containers healthy: `docker compose -f srcs/docker-compose.yml ps`
3. Review troubleshooting section above
4. Check DEV_DOC.md for development-specific issues
