# 13. Validacao e Troubleshooting

[Voltar ao Indice](00-INDICE.md) | [Anterior: Portainer](12-BONUS-PORTAINER.md) | [Proximo: Referencias](14-REFERENCIAS.md)

---

## Indice

1. [Checklist de Avaliacao](#1-checklist-de-avaliacao)
2. [Comandos de Validacao](#2-comandos-de-validacao)
3. [Testes Automatizados](#3-testes-automatizados)
4. [Problemas Comuns](#4-problemas-comuns)
5. [Debugging Containers](#5-debugging-containers)
6. [Logs e Monitoramento](#6-logs-e-monitoramento)
7. [Perguntas da Avaliacao](#7-perguntas-da-avaliacao)

---

## 1. Checklist de Avaliacao

### Requisitos Gerais

- [ ] Projeto executado em Virtual Machine
- [ ] `Makefile` na raiz configura toda a aplicacao via `docker-compose.yml`
- [ ] Arquivos de configuracao em `srcs/`
- [ ] Arquivo `.env` presente em `srcs/`
- [ ] Dominio `peda-cos.42.fr` aponta para IP local
- [ ] Sem senhas hardcoded nos Dockerfiles
- [ ] Variaveis de ambiente usadas corretamente

### Dockerfiles

- [ ] Um Dockerfile por servico
- [ ] Dockerfiles chamados pelo `docker-compose.yml`
- [ ] Base: Alpine ou Debian penultimate stable (Bullseye)
- [ ] **NAO** usa tag `latest`
- [ ] **NAO** usa imagens prontas (exceto Alpine/Debian base)
- [ ] Construidos do zero (sem `nginx:latest`, `wordpress:latest`, etc.)

### Containers Obrigatorios

| Container     | Requisitos                                                   |
| ------------- | ------------------------------------------------------------ |
| **NGINX**     | TLSv1.2 ou TLSv1.3 APENAS, unico ponto de entrada, porta 443 |
| **WordPress** | php-fpm instalado e configurado, sem nginx                   |
| **MariaDB**   | Sem nginx, volume para dados                                 |

### Network e Volumes

- [ ] Docker network customizada (nao usa `network: host`)
- [ ] **NAO** usa `--link` (deprecated)
- [ ] Volumes para WordPress database
- [ ] Volumes para WordPress files
- [ ] Volumes em `/home/peda-cos/data/`

### Seguranca e Boas Praticas

- [ ] Containers reiniciam em caso de crash (`restart: unless-stopped`)
- [ ] **NAO** usa comandos hacky (`tail -f`, `sleep infinity`, `while true`, `bash`)
- [ ] PID 1 e o daemon correto (nginx, php-fpm, mysqld)
- [ ] Sem loops infinitos em entrypoints

### WordPress

- [ ] 2 usuarios criados
- [ ] 1 usuario e administrador
- [ ] Nome do admin **NAO** contem "admin", "Admin", "administrator", etc.
- [ ] Segundo usuario nao e administrador

### Bonus (se aplicavel)

- [ ] Redis cache funcionando com WordPress
- [ ] Servidor FTP apontando para volume WordPress
- [ ] Adminer funcionando
- [ ] Site estatico sem PHP
- [ ] Servico extra util (Portainer)

---

## 2. Comandos de Validacao

### Verificar Containers

```bash
# Listar containers rodando
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Saida esperada:
# NAMES       STATUS          PORTS
# nginx       Up 2 minutes    0.0.0.0:443->443/tcp
# wordpress   Up 2 minutes    9000/tcp
# mariadb     Up 2 minutes    3306/tcp
# redis       Up 2 minutes    6379/tcp
# ...
```

### Verificar TLS

```bash
# Testar TLSv1.2
openssl s_client -connect peda-cos.42.fr:443 -tls1_2 2>/dev/null | grep -E "Protocol|Cipher"
# Esperado: Protocol  : TLSv1.2

# Testar TLSv1.3
openssl s_client -connect peda-cos.42.fr:443 -tls1_3 2>/dev/null | grep -E "Protocol|Cipher"
# Esperado: Protocol  : TLSv1.3

# Verificar que TLSv1.0 e TLSv1.1 NAO funcionam
openssl s_client -connect peda-cos.42.fr:443 -tls1 2>&1 | grep -i "error\|fail"
openssl s_client -connect peda-cos.42.fr:443 -tls1_1 2>&1 | grep -i "error\|fail"
# Esperado: Erros de conexao
```

### Verificar Portas Expostas

```bash
# Ver portas expostas para o host
docker ps --format "{{.Names}}: {{.Ports}}"

# APENAS porta 443 deve estar mapeada para 0.0.0.0
# Outras portas sao internas (ex: 9000/tcp sem mapeamento)

# Verificar com netstat
sudo netstat -tlnp | grep docker
# Esperado: apenas :443
```

### Verificar Network

```bash
# Listar networks
docker network ls

# Inspecionar network do projeto
docker network inspect inception_inception

# Verificar que containers estao na rede
docker network inspect inception_inception --format '{{range .Containers}}{{.Name}} {{end}}'
```

### Verificar Volumes

```bash
# Listar volumes
docker volume ls

# Verificar localizacao
docker volume inspect inception_wordpress_data --format '{{.Options.device}}'
# Esperado: /home/peda-cos/data/wordpress

docker volume inspect inception_db_data --format '{{.Options.device}}'
# Esperado: /home/peda-cos/data/mariadb

# Verificar dados persistem
ls -la /home/peda-cos/data/wordpress/
ls -la /home/peda-cos/data/mariadb/
```

### Verificar Dockerfiles

```bash
# Verificar que nao usa imagens prontas
grep -r "FROM" srcs/requirements/*/Dockerfile
# Esperado: apenas "FROM debian:bullseye" ou "FROM alpine:X.X"

# Verificar que nao usa latest
grep -r ":latest" srcs/requirements/*/Dockerfile
# Esperado: nenhum resultado

# Verificar senhas hardcoded
grep -rE "password|passwd|secret" srcs/requirements/*/Dockerfile
# Esperado: nenhum resultado (ou apenas comentarios)
```

### Verificar PID 1

```bash
# Ver processo PID 1 de cada container
docker exec nginx ps aux | head -2
# Esperado: nginx master process

docker exec wordpress ps aux | head -2
# Esperado: php-fpm master process

docker exec mariadb ps aux | head -2
# Esperado: mysqld
```

### Verificar Usuarios WordPress

```bash
# Listar usuarios
docker exec wordpress wp user list --path=/var/www/html --allow-root

# Verificar que nao tem "admin" no nome
docker exec wordpress wp user list --path=/var/www/html --allow-root --field=user_login | grep -i admin
# Esperado: nenhum resultado

# Verificar roles
docker exec wordpress wp user list --path=/var/www/html --allow-root --format=table
# Esperado: 1 administrator, 1 subscriber/author/editor
```

---

## 3. Testes Automatizados

### Script de Validacao Completo

```bash
#!/bin/bash
# scripts/validate.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="peda-cos.42.fr"
DATA_PATH="/home/peda-cos/data"

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "=========================================="
echo "  Inception - Validacao Automatica"
echo "=========================================="
echo ""

# ----------------------------------------------------------------------------
# 1. Containers rodando
# ----------------------------------------------------------------------------
echo "--- Verificando containers ---"

for container in nginx wordpress mariadb; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        pass "Container '$container' esta rodando"
    else
        fail "Container '$container' NAO esta rodando"
    fi
done

# ----------------------------------------------------------------------------
# 2. TLS
# ----------------------------------------------------------------------------
echo ""
echo "--- Verificando TLS ---"

if openssl s_client -connect ${DOMAIN}:443 -tls1_2 2>/dev/null | grep -q "Protocol.*TLSv1.2"; then
    pass "TLSv1.2 suportado"
else
    fail "TLSv1.2 NAO suportado"
fi

if openssl s_client -connect ${DOMAIN}:443 -tls1_3 2>/dev/null | grep -q "Protocol.*TLSv1.3"; then
    pass "TLSv1.3 suportado"
else
    warn "TLSv1.3 nao suportado (opcional dependendo do OpenSSL)"
fi

if openssl s_client -connect ${DOMAIN}:443 -tls1 2>&1 | grep -qi "error\|fail\|wrong"; then
    pass "TLSv1.0 corretamente BLOQUEADO"
else
    fail "TLSv1.0 NAO deveria estar habilitado!"
fi

# ----------------------------------------------------------------------------
# 3. Portas
# ----------------------------------------------------------------------------
echo ""
echo "--- Verificando portas ---"

EXPOSED_PORTS=$(docker ps --format '{{.Ports}}' | grep -o '0.0.0.0:[0-9]*' | sort -u)
if [ "$EXPOSED_PORTS" = "0.0.0.0:443" ]; then
    pass "Apenas porta 443 exposta para o host"
else
    fail "Portas expostas incorretas: $EXPOSED_PORTS"
fi

# ----------------------------------------------------------------------------
# 4. Volumes
# ----------------------------------------------------------------------------
echo ""
echo "--- Verificando volumes ---"

if [ -d "${DATA_PATH}/wordpress" ] && [ -d "${DATA_PATH}/mariadb" ]; then
    pass "Diretorios de volumes existem em ${DATA_PATH}"
else
    fail "Diretorios de volumes nao encontrados em ${DATA_PATH}"
fi

if [ "$(ls -A ${DATA_PATH}/wordpress 2>/dev/null)" ]; then
    pass "Volume WordPress contem dados"
else
    warn "Volume WordPress esta vazio"
fi

if [ "$(ls -A ${DATA_PATH}/mariadb 2>/dev/null)" ]; then
    pass "Volume MariaDB contem dados"
else
    warn "Volume MariaDB esta vazio"
fi

# ----------------------------------------------------------------------------
# 5. Dockerfiles
# ----------------------------------------------------------------------------
echo ""
echo "--- Verificando Dockerfiles ---"

if grep -rq ":latest" srcs/requirements/*/Dockerfile 2>/dev/null; then
    fail "Encontrado ':latest' em Dockerfiles"
else
    pass "Nenhum ':latest' encontrado"
fi

BASES=$(grep -h "^FROM" srcs/requirements/*/Dockerfile | sort -u)
if echo "$BASES" | grep -qvE "debian:bullseye|alpine:"; then
    fail "Base invalida encontrada: $BASES"
else
    pass "Bases corretas (Debian Bullseye ou Alpine)"
fi

# ----------------------------------------------------------------------------
# 6. PID 1
# ----------------------------------------------------------------------------
echo ""
echo "--- Verificando PID 1 ---"

NGINX_PID1=$(docker exec nginx ps -o comm= -p 1 2>/dev/null || echo "error")
if [ "$NGINX_PID1" = "nginx" ]; then
    pass "NGINX: PID 1 e nginx"
else
    fail "NGINX: PID 1 e '$NGINX_PID1' (esperado: nginx)"
fi

WP_PID1=$(docker exec wordpress ps -o comm= -p 1 2>/dev/null || echo "error")
if [ "$WP_PID1" = "php-fpm7.4" ] || [ "$WP_PID1" = "php-fpm" ]; then
    pass "WordPress: PID 1 e php-fpm"
else
    fail "WordPress: PID 1 e '$WP_PID1' (esperado: php-fpm7.4)"
fi

DB_PID1=$(docker exec mariadb ps -o comm= -p 1 2>/dev/null || echo "error")
if [ "$DB_PID1" = "mariadbd" ] || [ "$DB_PID1" = "mysqld" ]; then
    pass "MariaDB: PID 1 e mysqld/mariadbd"
else
    fail "MariaDB: PID 1 e '$DB_PID1' (esperado: mysqld)"
fi

# ----------------------------------------------------------------------------
# 7. Comandos proibidos
# ----------------------------------------------------------------------------
echo ""
echo "--- Verificando comandos proibidos ---"

FORBIDDEN="tail -f|sleep infinity|while true|bash$"
if grep -rE "$FORBIDDEN" srcs/requirements/*/tools/*.sh 2>/dev/null | grep -v "^#"; then
    fail "Encontrado comando proibido em scripts"
else
    pass "Nenhum comando proibido encontrado"
fi

# ----------------------------------------------------------------------------
# 8. WordPress usuarios
# ----------------------------------------------------------------------------
echo ""
echo "--- Verificando usuarios WordPress ---"

USER_COUNT=$(docker exec wordpress wp user list --path=/var/www/html --allow-root --format=count 2>/dev/null || echo "0")
if [ "$USER_COUNT" -ge 2 ]; then
    pass "WordPress tem $USER_COUNT usuarios (minimo 2)"
else
    fail "WordPress tem apenas $USER_COUNT usuario(s)"
fi

ADMIN_NAMES=$(docker exec wordpress wp user list --path=/var/www/html --allow-root --role=administrator --field=user_login 2>/dev/null)
if echo "$ADMIN_NAMES" | grep -qi "admin"; then
    fail "Usuario admin contem 'admin' no nome: $ADMIN_NAMES"
else
    pass "Nomes de admin nao contem 'admin'"
fi

# ----------------------------------------------------------------------------
# 9. WordPress funcionando
# ----------------------------------------------------------------------------
echo ""
echo "--- Verificando WordPress ---"

HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" https://${DOMAIN}/)
if [ "$HTTP_CODE" = "200" ]; then
    pass "WordPress respondendo (HTTP $HTTP_CODE)"
else
    fail "WordPress nao respondendo (HTTP $HTTP_CODE)"
fi

# ----------------------------------------------------------------------------
# 10. Network
# ----------------------------------------------------------------------------
echo ""
echo "--- Verificando network ---"

if docker network ls | grep -q "inception"; then
    pass "Network 'inception' existe"
else
    fail "Network 'inception' nao encontrada"
fi

# ----------------------------------------------------------------------------
# Resumo
# ----------------------------------------------------------------------------
echo ""
echo "=========================================="
echo -e "  ${GREEN}Validacao concluida com sucesso!${NC}"
echo "=========================================="
```

### Executar Validacao

```bash
# Dar permissao
chmod +x scripts/validate.sh

# Executar
./scripts/validate.sh
```

---

## 4. Problemas Comuns

### NGINX

#### "nginx: [emerg] bind() to 0.0.0.0:443 failed"

**Causa**: Porta 443 ja em uso

```bash
# Verificar quem usa a porta
sudo lsof -i :443
sudo netstat -tlnp | grep 443

# Parar servico conflitante
sudo systemctl stop apache2
sudo systemctl stop nginx
```

#### Certificado SSL invalido

**Causa**: Certificado nao existe ou expirado

```bash
# Verificar certificado
docker exec nginx ls -la /etc/nginx/ssl/

# Regenerar
docker exec nginx /usr/local/bin/generate-ssl.sh

# Verificar validade
docker exec nginx openssl x509 -in /etc/nginx/ssl/inception.crt -noout -dates
```

#### "502 Bad Gateway"

**Causa**: Backend (WordPress) nao esta respondendo

```bash
# Verificar se WordPress esta rodando
docker ps | grep wordpress

# Testar conexao interna
docker exec nginx ping -c 3 wordpress
docker exec nginx curl -v http://wordpress:9000/

# Ver logs do WordPress
docker logs wordpress
```

### MariaDB

#### "Access denied for user"

**Causa**: Senha incorreta ou usuario nao existe

```bash
# Verificar variaveis de ambiente
docker exec mariadb env | grep MYSQL

# Testar conexao
docker exec mariadb mysql -u wpuser -p

# Verificar usuarios
docker exec mariadb mysql -u root -p -e "SELECT User, Host FROM mysql.user;"
```

#### "Can't connect to MySQL server"

**Causa**: MariaDB ainda iniciando ou nao esta rodando

```bash
# Verificar status
docker exec mariadb mysqladmin ping -u root -p

# Ver logs
docker logs mariadb

# Verificar socket
docker exec mariadb ls -la /var/run/mysqld/
```

#### Dados perdidos apos restart

**Causa**: Volume nao configurado corretamente

```bash
# Verificar mounts
docker inspect mariadb --format '{{json .Mounts}}' | jq

# Verificar diretorio host
ls -la /home/peda-cos/data/mariadb/
```

### WordPress

#### "Error establishing a database connection"

**Causa**: Configuracao de banco incorreta

```bash
# Verificar wp-config.php
docker exec wordpress cat /var/www/html/wp-config.php | grep DB_

# Testar conexao do WordPress para MariaDB
docker exec wordpress ping -c 3 mariadb

# Verificar se banco existe
docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"
```

#### Tela branca (White Screen of Death)

**Causa**: Erro PHP

```bash
# Habilitar debug
docker exec wordpress sed -i "s/define('WP_DEBUG', false)/define('WP_DEBUG', true)/" /var/www/html/wp-config.php

# Ver erros
docker logs wordpress

# Verificar permissoes
docker exec wordpress ls -la /var/www/html/
```

#### Plugins/Temas nao instalam

**Causa**: Permissoes de arquivo

```bash
# Corrigir permissoes
docker exec wordpress chown -R www-data:www-data /var/www/html/wp-content/

# Verificar espaco em disco
docker exec wordpress df -h
```

### Docker Geral

#### "no space left on device"

**Causa**: Disco cheio

```bash
# Ver uso de disco Docker
docker system df

# Limpar imagens/containers nao usados
docker system prune -a

# Limpar volumes nao usados (CUIDADO!)
docker volume prune
```

#### Container reiniciando em loop

**Causa**: Erro no entrypoint

```bash
# Ver logs
docker logs --tail 100 <container>

# Ver eventos
docker events --filter container=<container>

# Inspecionar
docker inspect <container> --format '{{.State.ExitCode}}'
```

#### "network not found"

**Causa**: Network foi removida

```bash
# Recriar
docker network create inception

# Ou rebuildar tudo
make fclean && make
```

---

## 5. Debugging Containers

### Entrar no Container

```bash
# Shell interativo
docker exec -it nginx sh
docker exec -it wordpress bash
docker exec -it mariadb sh

# Como root (se necessario)
docker exec -it --user root wordpress bash
```

### Inspecionar Container

```bash
# Informacoes completas
docker inspect nginx

# Informacoes especificas
docker inspect nginx --format '{{.NetworkSettings.IPAddress}}'
docker inspect nginx --format '{{json .Config.Env}}' | jq
docker inspect nginx --format '{{json .Mounts}}' | jq
```

### Testar Conectividade

```bash
# Ping entre containers
docker exec nginx ping -c 3 wordpress
docker exec nginx ping -c 3 mariadb

# Testar porta
docker exec nginx nc -zv wordpress 9000
docker exec nginx nc -zv mariadb 3306

# DNS interno
docker exec nginx nslookup wordpress
```

### Verificar Processos

```bash
# Todos os processos
docker exec nginx ps aux

# Arvore de processos
docker exec nginx pstree -p

# Top em tempo real
docker exec -it nginx top
```

### Verificar Arquivos de Configuracao

```bash
# NGINX
docker exec nginx cat /etc/nginx/nginx.conf
docker exec nginx nginx -t

# PHP-FPM
docker exec wordpress cat /etc/php/7.4/fpm/php-fpm.conf
docker exec wordpress cat /etc/php/7.4/fpm/pool.d/www.conf

# MariaDB
docker exec mariadb cat /etc/mysql/mariadb.conf.d/50-server.cnf
```

---

## 6. Logs e Monitoramento

### Ver Logs

```bash
# Logs de um container
docker logs nginx
docker logs wordpress
docker logs mariadb

# Ultimas N linhas
docker logs --tail 50 nginx

# Seguir em tempo real
docker logs -f nginx

# Com timestamps
docker logs -t nginx

# Desde horario especifico
docker logs --since "2024-01-01T00:00:00" nginx
```

### Logs Combinados

```bash
# Via docker-compose
cd srcs
docker-compose logs -f

# Apenas alguns servicos
docker-compose logs -f nginx wordpress
```

### Estatisticas de Recursos

```bash
# Tempo real
docker stats

# Formato customizado
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Uma vez (sem stream)
docker stats --no-stream
```

### Monitorar Eventos

```bash
# Todos os eventos
docker events

# Filtrar por container
docker events --filter container=nginx

# Filtrar por tipo
docker events --filter type=container --filter event=die
```

---

## 7. Perguntas da Avaliacao

### Docker e Virtualizacao

**P: Qual a diferenca entre VM e Container?**

R: VMs virtualizam hardware completo com hypervisor, cada uma com seu proprio OS. Containers compartilham o kernel do host, virtualizando apenas o userspace, sendo mais leves e rapidos.

**P: O que e uma imagem Docker?**

R: Template read-only com instrucoes para criar container. Composta de layers empilhadas, onde cada instrucao do Dockerfile cria uma layer.

**P: O que e um container Docker?**

R: Instancia executavel de uma imagem. E a imagem em estado de execucao, com uma layer de escrita no topo.

### Configuracao

**P: Por que TLSv1.2/1.3 apenas?**

R: TLSv1.0 e 1.1 tem vulnerabilidades conhecidas (POODLE, BEAST). TLSv1.2+ sao considerados seguros atualmente.

**P: Por que nao usar `network: host`?**

R: `host` remove isolamento de rede, expoe todas as portas, e impede comunicacao por nome de container. Redes customizadas oferecem isolamento e DNS interno.

**P: Por que usar volumes ao inves de bind mounts?**

R: Volumes sao gerenciados pelo Docker, funcionam em qualquer OS, tem melhor performance, e podem ser facilmente backupeados.

**P: Por que nao hardcodar senhas?**

R: Dockerfiles sao versionados (git), imagens podem ser inspecionadas. Segredos devem vir de environment variables ou Docker Secrets.

### WordPress

**P: Por que 2 usuarios?**

R: Demonstra que o sistema de usuarios funciona. Um admin para gerenciar, outro para simular usuario comum.

**P: Por que admin nao pode ter "admin" no nome?**

R: Seguranca. Atacantes tentam "admin" primeiro em ataques de forca bruta.

### Boas Praticas

**P: Por que `restart: unless-stopped`?**

R: Garante que servicos reiniciem apos crashes ou reboots, mantendo alta disponibilidade.

**P: Por que nao usar `tail -f /dev/null`?**

R: E um "hack" que mantem container vivo artificialmente. O daemon deveria rodar em foreground naturalmente.

**P: O que e PID 1 e por que importa?**

R: Primeiro processo do container. Responsavel por repassar sinais (SIGTERM, etc.) e limpar processos zumbi. Deve ser o daemon principal.

---

## Comandos Rapidos para Avaliacao

```bash
# Status geral
docker ps -a

# Verificar TLS
openssl s_client -connect peda-cos.42.fr:443 -tls1_2

# Verificar usuarios WordPress
docker exec wordpress wp user list --path=/var/www/html --allow-root

# Verificar PID 1
docker exec nginx ps -o comm= -p 1

# Verificar volumes
docker volume ls
ls -la /home/peda-cos/data/

# Verificar network
docker network inspect inception_inception

# Verificar Dockerfiles
grep "^FROM" srcs/requirements/*/Dockerfile

# Testar restart
docker kill nginx && sleep 5 && docker ps | grep nginx
```

---

[Voltar ao Indice](00-INDICE.md) | [Anterior: Portainer](12-BONUS-PORTAINER.md) | [Proximo: Referencias](14-REFERENCIAS.md)
