# Documentacao do Desenvolvedor - Inception

Guia tecnico para desenvolvedores e administradores do sistema.

---

## Indice

1. [Arquitetura do Sistema](#arquitetura-do-sistema)
2. [Estrutura de Diretorios](#estrutura-de-diretorios)
3. [Configuracao do Ambiente](#configuracao-do-ambiente)
4. [Servicos](#servicos)
5. [Rede e Comunicacao](#rede-e-comunicacao)
6. [Volumes e Persistencia](#volumes-e-persistencia)
7. [Seguranca](#seguranca)
8. [Build e Deploy](#build-e-deploy)
9. [Monitoramento e Logs](#monitoramento-e-logs)
10. [Troubleshooting](#troubleshooting)
11. [Contribuindo](#contribuindo)

---

## Arquitetura do Sistema

### Visao Geral

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

### Fluxo de Requisicoes

1. Cliente faz requisicao HTTPS para `peda-cos.42.fr:443`
2. NGINX termina TLS e roteia baseado no hostname:
   - `peda-cos.42.fr` -> WordPress (FastCGI :9000)
   - `adminer.peda-cos.42.fr` -> Adminer (:8080)
   - `static.peda-cos.42.fr` -> Static Site (:8081)
   - `portainer.peda-cos.42.fr` -> Portainer (:9000)
3. WordPress consulta MariaDB e Redis conforme necessario
4. Resposta retorna pelo mesmo caminho

### Componentes

| Componente     | Tecnologia    | Responsabilidade                |
| -------------- | ------------- | ------------------------------- |
| Reverse Proxy  | NGINX 1.22    | TLS, roteamento, load balancing |
| Aplicacao      | WordPress 6.x | CMS, conteudo dinamico          |
| Runtime        | PHP-FPM 8.2   | Processamento PHP               |
| Banco de Dados | MariaDB 10.6  | Persistencia de dados           |
| Cache          | Redis 7.x     | Cache de objetos                |
| File Server    | vsftpd        | Acesso FTP aos arquivos         |
| DB Admin       | Adminer       | Interface web para BD           |
| Container Mgmt | Portainer     | Gerenciamento Docker            |

---

## Estrutura de Diretorios

```
inception/
├── Makefile                     # Automacao de build
├── README.md                    # Documentacao principal
├── USER_DOC.md                  # Documentacao do usuario
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
    ├── docker-compose.yml       # Orquestracao
    ├── .env                     # Variaveis de ambiente
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

## Configuracao do Ambiente

### Variaveis de Ambiente

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
| db_password      | `secrets/db_password.txt`      | Senha usuario WordPress |
| credentials      | `secrets/credentials.txt`      | Credenciais diversas    |

### Criando Secrets

```bash
# Gerar senhas aleatorias
openssl rand -base64 32 > secrets/db_root_password.txt
openssl rand -base64 32 > secrets/db_password.txt

# Credenciais WordPress
echo "admin_pass:$(openssl rand -base64 16)" > secrets/credentials.txt
echo "author_pass:$(openssl rand -base64 16)" >> secrets/credentials.txt
```

---

## Servicos

### NGINX

**Dockerfile:** `srcs/requirements/nginx/Dockerfile`

**Configuracao Principal:** `srcs/requirements/nginx/conf/nginx.conf`

**Responsabilidades:**

- Terminacao TLS (TLSv1.2/1.3)
- Reverse proxy para todos os servicos
- Servir arquivos estaticos
- Rate limiting e seguranca

**Portas:**

- 443 (HTTPS) - Exposta para o host

**Health Check:**

```bash
docker exec nginx nginx -t
curl -k https://peda-cos.42.fr/
```

### WordPress + PHP-FPM

**Dockerfile:** `srcs/requirements/wordpress/Dockerfile`

**Configuracoes:**

- PHP-FPM: `srcs/requirements/wordpress/conf/www.conf`
- WP Config: Gerado dinamicamente pelo setup.sh

**Responsabilidades:**

- Processar requisicoes PHP
- Gerenciar conteudo do CMS
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

**Configuracao:** `srcs/requirements/mariadb/conf/50-server.cnf`

**Responsabilidades:**

- Persistencia de dados
- Gerenciamento de usuarios
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
- Reducao de load no MariaDB

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

- Servir portfolio estatico
- Demonstrar site sem PHP

**Portas:**

- 8081 (HTTP) - Interna

### Portainer

**Dockerfile:** `srcs/requirements/bonus/portainer/Dockerfile`

**Responsabilidades:**

- Gerenciamento visual de containers
- Visualizacao de logs
- Acesso a terminal

**Portas:**

- 9000 (HTTP) - Interna

---

## Rede e Comunicacao

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

### Matriz de Comunicacao

| De \ Para | nginx | wordpress | mariadb | redis |
| --------- | ----- | --------- | ------- | ----- |
| nginx     | -     | 9000      | -       | -     |
| wordpress | -     | -         | 3306    | 6379  |
| mariadb   | -     | -         | -       | -     |
| redis     | -     | -         | -       | -     |

### Exposicao de Portas

```yaml
# Apenas NGINX expoe porta para o host
nginx:
  ports:
    - "443:443"

# Outros servicos sao internos
wordpress:
  expose:
    - "9000"
```

---

## Volumes e Persistencia

### Volumes Docker

| Volume         | Path no Host                  | Uso                |
| -------------- | ----------------------------- | ------------------ |
| wordpress_data | /home/peda-cos/data/wordpress | Arquivos WP        |
| db_data        | /home/peda-cos/data/mariadb   | Dados MariaDB      |
| redis_data     | /home/peda-cos/data/redis     | Persistencia Redis |
| portainer_data | /home/peda-cos/data/portainer | Config Portainer   |

### Configuracao de Volumes

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

## Seguranca

### Boas Praticas Implementadas

1. **TLS Obrigatorio**
   - Apenas TLSv1.2 e TLSv1.3
   - Ciphers modernos
   - HSTS habilitado

2. **Isolamento de Rede**
   - Network customizada
   - Apenas porta 443 exposta
   - Comunicacao interna por nome

3. **Secrets Management**
   - Senhas em Docker Secrets
   - Nao hardcoded em Dockerfiles
   - Gitignored

4. **Principio do Menor Privilegio**
   - Containers nao-root quando possivel
   - Volumes read-only onde aplicavel
   - Capabilities limitadas

5. **Health Checks**
   - Todos os servicos monitorados
   - Restart automatico em falha

### Checklist de Seguranca

- [ ] Trocar todas as senhas padrao
- [ ] Verificar permissoes de arquivos
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

# Verificar configuracao
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

# Iniciar servicos
make up

# Parar servicos
make down

# Limpar tudo
make fclean

# Rebuild
make re
```

### Build Individual

```bash
# Build servico especifico
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

### CI/CD (Sugestao)

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

### Logs por Servico

```bash
# Todos os servicos
docker-compose -f srcs/docker-compose.yml logs -f

# Servico especifico
docker logs -f nginx
docker logs -f wordpress
docker logs -f mariadb

# Ultimas N linhas
docker logs --tail 100 nginx
```

### Localizacao dos Logs

| Servico   | Container Path       | Descricao             |
| --------- | -------------------- | --------------------- |
| NGINX     | /var/log/nginx/      | Access e error logs   |
| PHP-FPM   | /var/log/php-fpm/    | PHP errors            |
| MariaDB   | stderr               | Query log, errors     |
| WordPress | wp-content/debug.log | Debug (se habilitado) |

### Metricas

```bash
# Uso de recursos
docker stats

# Formato customizado
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Alertas (Sugestao)

Para producao, considere:

- Prometheus + Grafana
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Uptime monitoring (UptimeRobot, Healthchecks.io)

---

## Troubleshooting

### Comandos de Diagnostico

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

#### Container nao inicia

```bash
# Ver logs de erro
docker logs <container>

# Verificar eventos
docker events --filter container=<container>

# Checar exit code
docker inspect <container> --format '{{.State.ExitCode}}'
```

#### Erro de conexao entre servicos

```bash
# Verificar se estao na mesma rede
docker network inspect inception_inception

# Testar DNS
docker exec nginx nslookup wordpress

# Testar porta
docker exec nginx nc -zv wordpress 9000
```

#### Problemas de permissao

```bash
# Verificar owner dos arquivos
docker exec wordpress ls -la /var/www/html/

# Corrigir permissoes
docker exec wordpress chown -R www-data:www-data /var/www/html/
```

#### Disco cheio

```bash
# Ver uso de disco Docker
docker system df

# Limpar recursos nao usados
docker system prune -a
```

---

## Contribuindo

### Workflow de Desenvolvimento

1. Criar branch para feature/fix
2. Fazer alteracoes
3. Testar localmente
4. Rodar validacao
5. Commit com mensagem descritiva
6. Push e criar PR

### Padroes de Codigo

**Dockerfiles:**

- Comentar cada secao
- Agrupar RUN commands
- Limpar cache na mesma layer
- Usar multi-stage quando aplicavel

**Scripts Shell:**

- Usar `set -e`
- Validar variaveis obrigatorias
- Usar `exec` para daemon final
- Comentar logica complexa

**Configuracoes:**

- Documentar cada opcao
- Usar valores seguros por padrao
- Separar por servico

### Testes

```bash
# Validacao completa
./scripts/validate.sh

# Testes individuais
docker exec nginx nginx -t
docker exec wordpress wp core is-installed --path=/var/www/html --allow-root
docker exec mariadb mysqladmin ping -u root -p
```

---

## Referencias

- [Tutorial Completo](docs/00-INDICE.md)
- [Docker Documentation](https://docs.docker.com/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [WordPress Developer](https://developer.wordpress.org/)

---

_Documentacao do Desenvolvedor - Inception v1.0_

**Autor:** peda-cos  
**Data:** Janeiro 2026  
**Versao:** 1.1
