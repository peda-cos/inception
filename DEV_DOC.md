# Documentação do Desenvolvedor - Inception

Guia técnico para desenvolvedores e administradores do sistema.

---

## Índice

1. [Arquitetura do Sistema](#arquitetura-do-sistema)
2. [Estrutura de Diretórios](#estrutura-de-diretórios)
3. [Configuração do Ambiente](#configuração-do-ambiente)
4. [Serviços](#serviços)
5. [Rede e Comunicação](#rede-e-comunicação)
6. [Volumes e Persistência](#volumes-e-persistência)
7. [Segurança](#segurança)
8. [Build e Deploy](#build-e-deploy)
9. [Monitoramento e Logs](#monitoramento-e-logs)
10. [Troubleshooting](#troubleshooting)
11. [Contribuindo](#contribuindo)

---

## Arquitetura do Sistema

### Visão Geral

```
                           Internet
                               |
                               | HTTPS (443)
                               v
+------------------------------------------------------------------+
|                          NGINX                                    |
|                    (TLSv1.2/1.3 Termination)                     |
+------------------------------------------------------------------+
        |              |              |              |
        v              v              v              v
+------------+  +------------+  +------------+  +------------+
| WordPress  |  | Adminer    |  | Static     |  | Portainer  |
| PHP-FPM    |  | PHP        |  | HTML/CSS   |  | API        |
| :9000      |  | :8080      |  | :8081      |  | :9000      |
+-----+------+  +------------+  +------------+  +------------+
      |
      v
+------------+     +------------+
| MariaDB    |<--->| Redis      |
| :3306      |     | :6379      |
+------------+     +------------+
```

### Fluxo de Requisições

1. Cliente faz requisição HTTPS para `peda-cos.42.fr:443`
2. NGINX termina TLS e roteia baseado no hostname:
   - `peda-cos.42.fr` -> WordPress (FastCGI :9000)
   - `adminer.peda-cos.42.fr` -> Adminer (:8080)
   - `static.peda-cos.42.fr` -> Static Site (:8081)
   - `portainer.peda-cos.42.fr` -> Portainer (:9000)
3. WordPress consulta MariaDB e Redis conforme necessário
4. Resposta retorna pelo mesmo caminho

### Componentes

| Componente     | Tecnologia    | Responsabilidade                |
| -------------- | ------------- | ------------------------------- |
| Reverse Proxy  | NGINX 1.22    | TLS, roteamento, load balancing |
| Aplicação      | WordPress 6.x | CMS, conteúdo dinâmico          |
| Runtime        | PHP-FPM 8.2   | Processamento PHP               |
| Banco de Dados | MariaDB 10.6  | Persistência de dados           |
| Cache          | Redis 7.x     | Cache de objetos                |
| File Server    | vsftpd        | Acesso FTP aos arquivos         |
| DB Admin       | Adminer       | Interface web para BD           |
| Container Mgmt | Portainer     | Gerenciamento Docker            |

---

## Estrutura de Diretórios

```
inception/
├── Makefile                     # Automação de build
├── README.md                    # Documentação principal
├── USER_DOC.md                  # Documentação do usuário
├── DEV_DOC.md                   # Este arquivo
├── secrets/                     # Credenciais (gitignored)
│   ├── db_root_password.txt
│   ├── db_password.txt
│   └── credentials.txt
├── docs/                        # Tutorial completo
│   ├── 00-INDICE.md
│   ├── 01-FUNDAMENTOS.md
│   └── ...
└── srcs/
    ├── docker-compose.yml       # Orquestração
    ├── .env                     # Variáveis de ambiente
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       └── generate-ssl.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── www.conf
        │   └── tools/
        │       └── setup.sh
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── init.sh
        └── bonus/
            ├── redis/
            ├── ftp/
            ├── adminer/
            ├── static/
            └── portainer/
```

---

## Configuração do Ambiente

### Variáveis de Ambiente

Arquivo: `srcs/.env`

```env
# Domain
DOMAIN_NAME=peda-cos.42.fr

# MariaDB
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

# WordPress
WP_TITLE=Inception
WP_ADMIN_USER=peda_admin
WP_ADMIN_EMAIL=peda-cos@student.42sp.org.br
WP_USER=peda_author
WP_USER_EMAIL=author@peda-cos.42.fr

# Paths
DATA_PATH=/home/peda-cos/data
```

### Docker Secrets

| Secret           | Arquivo                        | Uso                     |
| ---------------- | ------------------------------ | ----------------------- |
| db_root_password | `secrets/db_root_password.txt` | Senha root MariaDB      |
| db_password      | `secrets/db_password.txt`      | Senha usuário WordPress |
| credentials      | `secrets/credentials.txt`      | Credenciais diversas    |

### Criando Secrets

```bash
# Gerar senhas aleatórias
openssl rand -base64 32 > secrets/db_root_password.txt
openssl rand -base64 32 > secrets/db_password.txt

# Credenciais WordPress
echo "admin_pass:$(openssl rand -base64 16)" > secrets/credentials.txt
echo "author_pass:$(openssl rand -base64 16)" >> secrets/credentials.txt
```

---

## Serviços

### NGINX

**Dockerfile:** `srcs/requirements/nginx/Dockerfile`

**Configuração Principal:** `srcs/requirements/nginx/conf/nginx.conf`

**Responsabilidades:**

- Terminação TLS (TLSv1.2/1.3)
- Reverse proxy para todos os serviços
- Servir arquivos estáticos
- Rate limiting e segurança

**Portas:**

- 443 (HTTPS) - Exposta para o host

**Health Check:**

```bash
docker exec nginx nginx -t
curl -k https://peda-cos.42.fr/
```

### WordPress + PHP-FPM

**Dockerfile:** `srcs/requirements/wordpress/Dockerfile`

**Configurações:**

- PHP-FPM: `srcs/requirements/wordpress/conf/www.conf`
- WP Config: Gerado dinamicamente pelo setup.sh

**Responsabilidades:**

- Processar requisições PHP
- Gerenciar conteúdo do CMS
- Comunicar com MariaDB e Redis

**Portas:**

- 9000 (PHP-FPM) - Interna

**Health Check:**

```bash
docker exec wordpress php-fpm8.2 -t
docker exec wordpress wp core is-installed --path=/var/www/html --allow-root
```

### MariaDB

**Dockerfile:** `srcs/requirements/mariadb/Dockerfile`

**Configuração:** `srcs/requirements/mariadb/conf/50-server.cnf`

**Responsabilidades:**

- Persistência de dados
- Gerenciamento de usuários
- Backup e recovery

**Portas:**

- 3306 (MySQL) - Interna

**Health Check:**

```bash
docker exec mariadb mysqladmin ping -u root -p
docker exec mariadb mysql -u wpuser -p -e "SHOW DATABASES;"
```

### Redis

**Dockerfile:** `srcs/requirements/bonus/redis/Dockerfile`

**Responsabilidades:**

- Cache de objetos para WordPress
- Session storage
- Redução de load no MariaDB

**Portas:**

- 6379 (Redis) - Interna

**Health Check:**

```bash
docker exec redis redis-cli ping
docker exec redis redis-cli info memory
```

### FTP (vsftpd)

**Dockerfile:** `srcs/requirements/bonus/ftp/Dockerfile`

**Responsabilidades:**

- Acesso FTP ao volume WordPress
- Upload de temas/plugins

**Portas:**

- 21 (FTP control) - Pode ser exposta
- 21000-21010 (Passive) - Range passivo

### Adminer

**Dockerfile:** `srcs/requirements/bonus/adminer/Dockerfile`

**Responsabilidades:**

- Interface web para MariaDB
- Gerenciamento de banco de dados
- Backup/restore

**Portas:**

- 8080 (HTTP) - Interna

### Static Site

**Dockerfile:** `srcs/requirements/bonus/static/Dockerfile`

**Responsabilidades:**

- Servir portfólio estático
- Demonstrar site sem PHP

**Portas:**

- 8081 (HTTP) - Interna

### Portainer

**Dockerfile:** `srcs/requirements/bonus/portainer/Dockerfile`

**Responsabilidades:**

- Gerenciamento visual de containers
- Visualização de logs
- Acesso a terminal

**Portas:**

- 9000 (HTTP) - Interna

---

## Rede e Comunicação

### Docker Network

```yaml
networks:
  inception:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### DNS Interno

Containers podem se comunicar por nome:

- `nginx` -> 172.20.0.x
- `wordpress` -> 172.20.0.x
- `mariadb` -> 172.20.0.x
- `redis` -> 172.20.0.x

### Matriz de Comunicação

| De \ Para | nginx | wordpress | mariadb | redis |
| --------- | ----- | --------- | ------- | ----- |
| nginx     | -     | 9000      | -       | -     |
| wordpress | -     | -         | 3306    | 6379  |
| mariadb   | -     | -         | -       | -     |
| redis     | -     | -         | -       | -     |

### Exposição de Portas

```yaml
# Apenas NGINX expõe porta para o host
nginx:
  ports:
    - "443:443"

# Outros serviços são internos
wordpress:
  expose:
    - "9000"
```

---

## Volumes e Persistência

### Volumes Docker

| Volume         | Path no Host                  | Uso                |
| -------------- | ----------------------------- | ------------------ |
| wordpress_data | /home/peda-cos/data/wordpress | Arquivos WP        |
| db_data        | /home/peda-cos/data/mariadb   | Dados MariaDB      |
| redis_data     | /home/peda-cos/data/redis     | Persistência Redis |
| portainer_data | /home/peda-cos/data/portainer | Config Portainer   |

### Configuração de Volumes

```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/peda-cos/data/wordpress

  db_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/peda-cos/data/mariadb
```

### Backup

```bash
# Backup MariaDB
docker exec mariadb mysqldump -u root -p wordpress > backup.sql

# Backup WordPress files
tar -czvf wordpress_files.tar.gz /home/peda-cos/data/wordpress/

# Backup completo
./scripts/backup.sh
```

### Restore

```bash
# Restore MariaDB
docker exec -i mariadb mysql -u root -p wordpress < backup.sql

# Restore WordPress files
tar -xzvf wordpress_files.tar.gz -C /
```

---

## Segurança

### Boas Práticas Implementadas

1. **TLS Obrigatório**
   - Apenas TLSv1.2 e TLSv1.3
   - Ciphers modernos
   - HSTS habilitado

2. **Isolamento de Rede**
   - Network customizada
   - Apenas porta 443 exposta
   - Comunicação interna por nome

3. **Secrets Management**
   - Senhas em Docker Secrets
   - Não hardcoded em Dockerfiles
   - Gitignored

4. **Princípio do Menor Privilégio**
   - Containers não-root quando possível
   - Volumes read-only onde aplicável
   - Capabilities limitadas

5. **Health Checks**
   - Todos os serviços monitorados
   - Restart automático em falha

### Checklist de Segurança

- [ ] Trocar todas as senhas padrão
- [ ] Verificar permissões de arquivos
- [ ] Revisar logs regularmente
- [ ] Manter imagens atualizadas
- [ ] Escanear vulnerabilidades (Trivy)
- [ ] Backup regular e testado

### Hardening Adicional

```bash
# Escanear imagens
trivy image nginx:local
trivy image wordpress:local
trivy image mariadb:local

# Verificar configuração
docker-bench-security
```

---

## Build e Deploy

### Comandos Make

```makefile
# Build completo
make

# Apenas build imagens
make build

# Iniciar serviços
make up

# Parar serviços
make down

# Limpar tudo
make fclean

# Rebuild
make re
```

### Build Individual

```bash
# Build serviço específico
docker-compose -f srcs/docker-compose.yml build nginx
docker-compose -f srcs/docker-compose.yml build wordpress

# Build sem cache
docker-compose -f srcs/docker-compose.yml build --no-cache
```

### Deploy Steps

1. **Preparar ambiente:**

   ```bash
   mkdir -p /home/peda-cos/data/{wordpress,mariadb,redis,portainer}
   ```

2. **Configurar secrets:**

   ```bash
   ./scripts/generate-secrets.sh
   ```

3. **Configurar DNS:**

   ```bash
   ./scripts/setup-hosts.sh
   ```

4. **Build e deploy:**

   ```bash
   make
   ```

5. **Validar:**
   ```bash
   ./scripts/validate.sh
   ```

### CI/CD (Sugestão)

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build images
        run: make build
      - name: Run tests
        run: ./scripts/validate.sh
```

---

## Monitoramento e Logs

### Logs por Serviço

```bash
# Todos os serviços
docker-compose -f srcs/docker-compose.yml logs -f

# Serviço específico
docker logs -f nginx
docker logs -f wordpress
docker logs -f mariadb

# Últimas N linhas
docker logs --tail 100 nginx
```

### Localização dos Logs

| Serviço   | Container Path       | Descrição             |
| --------- | -------------------- | --------------------- |
| NGINX     | /var/log/nginx/      | Access e error logs   |
| PHP-FPM   | /var/log/php-fpm/    | PHP errors            |
| MariaDB   | stderr               | Query log, errors     |
| WordPress | wp-content/debug.log | Debug (se habilitado) |

### Métricas

```bash
# Uso de recursos
docker stats

# Formato customizado
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Alertas (Sugestão)

Para produção, considere:

- Prometheus + Grafana
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Uptime monitoring (UptimeRobot, Healthchecks.io)

---

## Troubleshooting

### Comandos de Diagnóstico

```bash
# Status dos containers
docker ps -a

# Inspecionar container
docker inspect <container>

# Entrar no container
docker exec -it <container> sh

# Ver processos
docker exec <container> ps aux

# Verificar rede
docker network inspect inception_inception

# Testar conectividade
docker exec nginx ping wordpress
docker exec wordpress ping mariadb
```

### Problemas Frequentes

#### Container não inicia

```bash
# Ver logs de erro
docker logs <container>

# Verificar eventos
docker events --filter container=<container>

# Checar exit code
docker inspect <container> --format '{{.State.ExitCode}}'
```

#### Erro de conexão entre serviços

```bash
# Verificar se estão na mesma rede
docker network inspect inception_inception

# Testar DNS
docker exec nginx nslookup wordpress

# Testar porta
docker exec nginx nc -zv wordpress 9000
```

#### Problemas de permissão

```bash
# Verificar owner dos arquivos
docker exec wordpress ls -la /var/www/html/

# Corrigir permissões
docker exec wordpress chown -R www-data:www-data /var/www/html/
```

#### Disco cheio

```bash
# Ver uso de disco Docker
docker system df

# Limpar recursos não usados
docker system prune -a
```

---

## Contribuindo

### Workflow de Desenvolvimento

1. Criar branch para feature/fix
2. Fazer alterações
3. Testar localmente
4. Rodar validação
5. Commit com mensagem descritiva
6. Push e criar PR

### Padrões de Código

**Dockerfiles:**

- Comentar cada seção
- Agrupar RUN commands
- Limpar cache na mesma layer
- Usar multi-stage quando aplicável

**Scripts Shell:**

- Usar `set -e`
- Validar variáveis obrigatórias
- Usar `exec` para daemon final
- Comentar lógica complexa

**Configurações:**

- Documentar cada opção
- Usar valores seguros por padrão
- Separar por serviço

### Testes

```bash
# Validação completa
./scripts/validate.sh

# Testes individuais
docker exec nginx nginx -t
docker exec wordpress wp core is-installed --path=/var/www/html --allow-root
docker exec mariadb mysqladmin ping -u root -p
```

---

## Referências

- [Tutorial Completo](docs/00-INDICE.md)
- [Docker Documentation](https://docs.docker.com/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [WordPress Developer](https://developer.wordpress.org/)

---

_Documentação do Desenvolvedor - Inception v1.0_

**Autor:** peda-cos  
**Data:** Janeiro 2026  
**Versão:** 1.1
