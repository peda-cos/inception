# 03 - Estrutura do Projeto

[Voltar ao Índice](./00-INDICE.md) | [Anterior: Preparação](./02-PREPARACAO-AMBIENTE.md)

---

## Sumário

1. [Visão Geral da Estrutura](#1-visão-geral-da-estrutura)
2. [Criando a Estrutura de Diretórios](#2-criando-a-estrutura-de-diretórios)
3. [Makefile](#3-makefile)
4. [Arquivo .env](#4-arquivo-env)
5. [Docker Secrets](#5-docker-secrets)
6. [Arquivos .dockerignore](#6-arquivos-dockerignore)
7. [.gitignore](#7-gitignore)

---

## 1. Visão Geral da Estrutura

Estrutura completa do projeto conforme exigido pelo subject:

```
inception/
├── Makefile                           # Automação de comandos
├── README.md                          # Documentação principal
├── USER_DOC.md                        # Documentação do usuário
├── DEV_DOC.md                         # Documentação do desenvolvedor
├── .gitignore                         # Arquivos ignorados pelo Git
├── secrets/                           # Docker Secrets (senhas)
│   ├── credentials.txt                # Credenciais WordPress
│   ├── db_password.txt                # Senha do usuário do banco
│   ├── db_root_password.txt           # Senha root do MariaDB
│   └── ftp_password.txt               # Senha do usuário FTP (bônus)
└── srcs/
    ├── docker-compose.yml             # Orquestração dos serviços
    ├── .env                           # Variáveis de ambiente
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── 50-server.cnf      # Configuração MariaDB
        │   └── tools/
        │       └── init.sh            # Script de inicialização
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── nginx.conf         # Configuração NGINX
        │   └── tools/
        │       └── setup-ssl.sh       # Geração de certificados
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── www.conf           # Configuração PHP-FPM
        │   └── tools/
        │       └── init.sh            # Script de inicialização
        └── bonus/                     # Serviços bônus
            ├── redis/
            ├── ftp/
            ├── adminer/
            ├── static-site/
            └── portainer/
```

---

## 2. Criando a Estrutura de Diretórios

### Script de Criação

Execute na raiz do seu projeto:

```bash
#!/bin/bash

mkdir -p inception
cd inception

mkdir -p secrets
mkdir -p srcs/requirements/mariadb/{conf,tools}
mkdir -p srcs/requirements/nginx/{conf,tools}
mkdir -p srcs/requirements/wordpress/{conf,tools}

mkdir -p srcs/requirements/bonus/redis/{conf,tools}
mkdir -p srcs/requirements/bonus/ftp/{conf,tools}
mkdir -p srcs/requirements/bonus/adminer/{conf,tools}
mkdir -p srcs/requirements/bonus/static-site/{conf,tools}
mkdir -p srcs/requirements/bonus/portainer/{conf,tools}

touch Makefile
touch README.md
touch USER_DOC.md
touch DEV_DOC.md
touch .gitignore
touch secrets/credentials.txt
touch secrets/db_password.txt
touch secrets/db_root_password.txt
touch secrets/ftp_password.txt
touch srcs/docker-compose.yml
touch srcs/.env

touch srcs/requirements/mariadb/Dockerfile
touch srcs/requirements/mariadb/.dockerignore
touch srcs/requirements/nginx/Dockerfile
touch srcs/requirements/nginx/.dockerignore
touch srcs/requirements/wordpress/Dockerfile
touch srcs/requirements/wordpress/.dockerignore

echo "Estrutura criada com sucesso!"
tree . 2>/dev/null || find . -type f | head -30
```

Salve como `create_structure.sh`, dê permissão e execute:

```bash
chmod +x create_structure.sh
./create_structure.sh
```

---

## 3. Makefile

O Makefile é **obrigatório** e deve estar na **raiz do projeto**.

### Makefile Completo

```makefile
COMPOSE = docker compose -f srcs/docker-compose.yml
DATA_PATH = /home/peda-cos/data

all:
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	@echo "Building and starting mandatory services..."
	@$(COMPOSE) up -d --build nginx wordpress mariadb
	@echo "Done! WordPress: https://peda-cos.42.fr"

bonus: all
	@mkdir -p $(DATA_PATH)/redis
	@mkdir -p $(DATA_PATH)/portainer
	@echo "Building and starting bonus services..."
	@$(COMPOSE) up -d --build redis ftp adminer static-site portainer
	@echo "Bonus services started!"

clean:
	@$(COMPOSE) down
	@echo "Cleaned."

fclean: clean
	@$(COMPOSE) down -v
	@docker stop $$(docker ps -aq) 2>/dev/null || true
	@docker rm -f $$(docker ps -aq) 2>/dev/null || true
	@docker system prune -a --volumes -f
	@sudo rm -rf $(DATA_PATH)
	@docker images
	@docker ps -a
	@echo "Fully cleaned."

re: fclean all

.PHONY: all bonus clean fclean re
```

---

## 4. Arquivo .env

O arquivo `.env` armazena variáveis de ambiente. Fica em `srcs/.env`.

### srcs/.env

```env
DOMAIN_NAME=peda-cos.42.fr

MYSQL_ROOT_PASSWORD_FILE=/run/secrets/db_root_password
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD_FILE=/run/secrets/db_password

WORDPRESS_DB_HOST=mariadb:3306
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wpuser
WORDPRESS_DB_PASSWORD_FILE=/run/secrets/db_password

# Username must NOT contain "admin" (subject requirement)
WORDPRESS_ADMIN_USER=supervisor
WORDPRESS_ADMIN_EMAIL=peda-cos@student.42sp.org.br

WORDPRESS_USER=editor
WORDPRESS_USER_EMAIL=editor@peda-cos.42.fr
WORDPRESS_USER_ROLE=editor

WORDPRESS_TITLE=Inception - peda-cos

NGINX_HOST=peda-cos.42.fr
NGINX_PORT=443

REDIS_HOST=redis
REDIS_PORT=6379

FTP_USER=ftpuser
```

### Variáveis Importantes

| Variável               | Descrição              | Valor                     |
| ---------------------- | ---------------------- | ------------------------- |
| `DOMAIN_NAME`          | Domínio do site        | `peda-cos.42.fr`          |
| `MYSQL_DATABASE`       | Nome do banco de dados | `wordpress`               |
| `MYSQL_USER`           | Usuário do banco       | `wpuser`                  |
| `WORDPRESS_ADMIN_USER` | Admin do WordPress     | **NÃO pode ser "admin"!** |
| `WORDPRESS_DB_HOST`    | Host do banco          | `mariadb:3306`            |

---

## 5. Docker Secrets

Secrets armazenam dados sensíveis de forma segura. Ficam no diretório `secrets/`.

### secrets/db_root_password.txt

```
SuaSenhaRootForte123!
```

### secrets/db_password.txt

```
SenhaDoBancoForte456!
```

### secrets/credentials.txt

```
WORDPRESS_ADMIN_PASSWORD=SenhaDoAdmin789!
WORDPRESS_USER_PASSWORD=SenhaDoEditor321!
```

### secrets/ftp_password.txt (Bônus)

```
SenhaFTPForte789!
```

### Permissões dos Arquivos de Secrets

```bash
chmod 600 secrets/*
```

### Como usar Secrets no docker-compose.yml

```yaml
services:
  mariadb:
    secrets:
      - db_password
      - db_root_password

secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt
```

### Como ler Secrets nos Scripts

```bash
#!/bin/sh

DB_PASSWORD=$(cat /run/secrets/db_password)

mysql -u root -p"${DB_PASSWORD}" -e "SHOW DATABASES;"
```

---

## 6. Arquivos .dockerignore

Cada serviço deve ter seu `.dockerignore` para otimizar o build.

### srcs/requirements/mariadb/.dockerignore

```dockerignore
.git
.gitignore
*.md
README*
LICENSE
*.log
*.tmp
*.swp
*~
*.bak
*.backup
data/
```

### srcs/requirements/nginx/.dockerignore

```dockerignore
.git
.gitignore
*.md
README*
LICENSE
*.log
logs/
*.tmp
*.swp
*~
*.pem
*.key
*.crt
!conf/*.conf
```

### srcs/requirements/wordpress/.dockerignore

```dockerignore
.git
.gitignore
*.md
README*
LICENSE
*.log
*.tmp
*.swp
*~
node_modules/
wp-content/uploads/
wp-content/cache/
```

---

## 7. .gitignore

Na raiz do projeto, crie um `.gitignore` para proteger dados sensíveis.

### .gitignore

```gitignore
# NEVER commit real secrets!
# secrets/db_password.txt
# secrets/db_root_password.txt
# secrets/credentials.txt

/home/*/data/

# srcs/.env

.DS_Store
Thumbs.db

*.swp
*.swo
*~
.idea/
.vscode/
*.sublime-*

*.log
logs/

*.tmp
*.temp

*.tar
*.gz

*.pem
*.key
*.crt
*.csr

core
```

### Nota sobre Secrets e Git

O subject diz:

> "Any credentials, API keys, or passwords found in your Git repository (outside of properly configured secrets) will result in project failure."

**Recomendações:**

1. **Para desenvolvimento**: Use senhas de teste nos arquivos de secrets
2. **Para produção**: Adicione secrets ao `.gitignore` e crie manualmente
3. **Nunca commite senhas reais** no repositório

---

## Verificação da Estrutura

Execute este comando para verificar:

```bash
tree -a -I '.git' inception/ 2>/dev/null || find inception/ -type f | sort
```

Saída esperada:

```
inception/
├── .gitignore
├── DEV_DOC.md
├── Makefile
├── README.md
├── USER_DOC.md
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── ftp_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── .dockerignore
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── .dockerignore
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── .dockerignore
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── bonus/
            └── ...
```

---

## Próxima Etapa

Agora vamos implementar o primeiro container - MariaDB:

[Ir para 04-MARIADB.md](./04-MARIADB.md)
