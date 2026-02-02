# Secret Management Guide

## Overview
All real secrets for this project are stored **outside the repository** in `~/secrets/` on the VM. This ensures sensitive credentials never get committed to version control.

## Directory Structure

```
~/secrets/              # VM only - NOT in repository
├── .env               # Master environment file with all secrets
├── credentials.txt    # WordPress admin/user passwords
├── db_password.txt    # Database user password
├── db_root_password.txt  # Database root password
└── ftp_password.txt   # FTP user password
```

## How It Works

### 1. Environment Variables
The `~/secrets/.env` file contains all environment variables and secrets:
- Database credentials
- WordPress admin credentials
- FTP passwords
- Domain configuration
- Service ports and hostnames

### 2. Docker Secrets
Docker Compose uses individual `.txt` files from `~/secrets/` as Docker secrets:
- These are mounted into containers at `/run/secrets/`
- Applications read passwords from these mounted files
- This follows Docker security best practices

### 3. Docker Compose Configuration
The `Makefile` automatically uses the correct .env file:
```make
COMPOSE = docker compose -f srcs/docker-compose.yml --env-file /home/peda-cos/secrets/.env
```

The `docker-compose.yml` references secrets using absolute paths:
```yaml
secrets:
  db_password:
    file: /home/peda-cos/secrets/db_password.txt
  # ... other secrets
```

## Setup Instructions

### First Time Setup
1. Ensure `~/secrets/` directory exists with proper permissions:
   ```bash
   mkdir -p ~/secrets
   chmod 700 ~/secrets
   ```

2. Verify all secret files exist:
   ```bash
   ls -la ~/secrets/
   ```
   Should show:
   - `.env`
   - `credentials.txt`
   - `db_password.txt`
   - `db_root_password.txt`
   - `ftp_password.txt`

3. Run the project normally:
   ```bash
   make
   ```

### Updating Secrets
To update passwords or secrets:

1. Edit `~/secrets/.env` with your changes
2. Update the corresponding individual `.txt` files if needed
3. Restart affected services:
   ```bash
   make clean
   make
   ```

## Security Features

### ✅ What's Protected
- Real passwords are **only** in `~/secrets/` (VM filesystem)
- Repository contains **no real secrets**
- `.gitignore` blocks entire `secrets/` directory and all `.env` files
- Docker secrets are passed securely via mounted files

### ✅ Repository State
- The repository contains **dummy passwords** for reference
- After initial commits, secrets are removed from git tracking
- Anyone cloning the repo gets templates, not real credentials

### ⚠️ Important Notes
1. **Never commit ~/secrets/ contents to git**
2. **Keep ~/secrets/ directory permissions restricted** (700)
3. **Backup ~/secrets/.env separately** (not in repo)
4. **Use different passwords in production**

## File Relationships

```
Repository (git tracked):
├── srcs/
│   ├── docker-compose.yml    → references /home/peda-cos/secrets/*.txt
│   └── .env.example          → template (no real secrets)
├── Makefile                  → uses --env-file /home/peda-cos/secrets/.env
└── .gitignore               → excludes secrets/ and *.env

VM Filesystem (NOT in git):
└── ~/secrets/
    ├── .env                 → master config (read by docker-compose)
    ├── credentials.txt      → WordPress passwords (Docker secret)
    ├── db_password.txt      → Database password (Docker secret)
    ├── db_root_password.txt → DB root password (Docker secret)
    └── ftp_password.txt     → FTP password (Docker secret)
```

## Troubleshooting

### "No such file or directory" for secrets
Ensure `~/secrets/` exists and contains all required files:
```bash
ls ~/secrets/
```

### Environment variables not loading
Check the Makefile is using the correct --env-file path:
```bash
grep "env-file" Makefile
```

### Docker secrets not working
Verify absolute paths in docker-compose.yml:
```bash
grep "file:" srcs/docker-compose.yml
```

## Migration Notes

This project was refactored to:
1. Move secrets from `./secrets/` (repository) to `~/secrets/` (VM only)
2. Replace real secrets with dummy passwords in repository
3. Update all references to use absolute VM paths
4. Add proper .gitignore rules

All real secrets are now safely outside version control! 🔒
