# 13. Validação e Troubleshooting

[Voltar ao Índice](00-INDICE.md) | [Anterior: Portainer](12-BONUS-PORTAINER.md) | [Próximo: Referências](14-REFERENCIAS.md)

---

## Índice

1. [Checklist de Avaliação](#1-checklist-de-avaliacao)
2. [Comandos de Validação](#2-comandos-de-validacao)
3. [Testes Automatizados](#3-testes-automatizados)
4. [Problemas Comuns](#4-problemas-comuns)
5. [Debugging Containers](#5-debugging-containers)
6. [Logs e Monitoramento](#6-logs-e-monitoramento)
7. [Perguntas da Avaliação](#7-perguntas-da-avaliacao)

---

## 1. Checklist de Avaliação

### Requisitos Gerais

- [ ] Projeto executado em Virtual Machine
- [ ] `Makefile` na raiz configura toda a aplicação via `docker-compose.yml`
- [ ] Arquivos de configuração em `srcs/`
- [ ] Arquivo `.env` presente em `srcs/`
- [ ] Domínio `peda-cos.42.fr` aponta para IP local
- [ ] Sem senhas hardcoded nos Dockerfiles
- [ ] Variáveis de ambiente usadas corretamente

### Dockerfiles

- [ ] Um Dockerfile por serviço
- [ ] Dockerfiles chamados pelo `docker-compose.yml`
- [ ] Base: Alpine ou Debian penultimate stable (Bullseye)
- [ ] **NÃO** usa tag `latest`
- [ ] **NÃO** usa imagens prontas (exceto Alpine/Debian base)
- [ ] Construídos do zero (sem `nginx:latest`, `wordpress:latest`, etc.)

### Containers Obrigatórios

| Container     | Requisitos                                                   |
| ------------- | ------------------------------------------------------------ |
| **NGINX**     | TLSv1.2 ou TLSv1.3 APENAS, único ponto de entrada, porta 443 |
| **WordPress** | php-fpm instalado e configurado, sem nginx                   |
| **MariaDB**   | Sem nginx, volume para dados                                 |

### Network e Volumes

- [ ] Docker network customizada (não usa `network: host`)
- [ ] **NÃO** usa `--link` (deprecated)
- [ ] Volumes para WordPress database
- [ ] Volumes para WordPress files
- [ ] Volumes em `/home/peda-cos/data/`

### Segurança e Boas Práticas

- [ ] Containers reiniciam em caso de crash (`restart: unless-stopped`)
- [ ] **NÃO** usa comandos hacky (`tail -f`, `sleep infinity`, `while true`, `bash`)
- [ ] PID 1 é o daemon correto (nginx, php-fpm, mysqld)
- [ ] Sem loops infinitos em entrypoints

### WordPress

- [ ] 2 usuários criados
- [ ] 1 usuário é administrador
- [ ] Nome do admin **NÃO** contém "admin", "Admin", "administrator", etc.
- [ ] Segundo usuário não é administrador

### Bonus (se aplicável)

- [ ] Redis cache funcionando com WordPress
- [ ] Servidor FTP apontando para volume WordPress
- [ ] Adminer funcionando
- [ ] Site estático sem PHP
- [ ] Serviço extra útil (Portainer)

---

## 2. Comandos de Validação

### Verificar Containers

```bash
# Listar containers rodando
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Saída esperada:
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

# Verificar que TLSv1.0 e TLSv1.1 NÃO funcionam
openssl s_client -connect peda-cos.42.fr:443 -tls1 2>&1 | grep -i "error\|fail"
openssl s_client -connect peda-cos.42.fr:443 -tls1_1 2>&1 | grep -i "error\|fail"
# Esperado: Erros de conexão
```

### Verificar Portas Expostas

```bash
# Ver portas expostas para o host
docker ps --format "{{.Names}}: {{.Ports}}"

# APENAS porta 443 deve estar mapeada para 0.0.0.0
# Outras portas são internas (ex: 9000/tcp sem mapeamento)

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

# Verificar que containers estão na rede
docker network inspect inception_inception --format '{{range .Containers}}{{.Name}} {{end}}'
```

### Verificar Volumes

```bash
# Listar volumes
docker volume ls

# Verificar localização
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
# Verificar que não usa imagens prontas
grep -r "FROM" srcs/requirements/*/Dockerfile
# Esperado: apenas "FROM debian:oldstable" ou "FROM alpine:X.X"

# Verificar que não usa latest
grep -r ":latest" srcs/requirements/*/Dockerfile
# Esperado: nenhum resultado

# Verificar senhas hardcoded
grep -rE "password|passwd|secret" srcs/requirements/*/Dockerfile
# Esperado: nenhum resultado (ou apenas comentários)
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

### Verificar Usuários WordPress

```bash
# Listar usuários
docker exec wordpress wp user list --path=/var/www/html --allow-root

# Verificar que não tem "admin" no nome
docker exec wordpress wp user list --path=/var/www/html --allow-root --field=user_login | grep -i admin
# Esperado: nenhum resultado

# Verificar roles
docker exec wordpress wp user list --path=/var/www/html --allow-root --format=table
# Esperado: 1 administrator, 1 subscriber/author/editor
```

---

## 3. Testes Automatizados

### Script de Validação Completo

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
if echo "$BASES" | grep -qvE "debian:oldstable|alpine:"; then
    fail "Base invalida encontrada: $BASES"
else
    pass "Bases corretas (Debian oldstable ou Alpine)"
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
if [ "$WP_PID1" = "php-fpm8.2" ] || [ "$WP_PID1" = "php-fpm" ]; then
    pass "WordPress: PID 1 e php-fpm"
else
    fail "WordPress: PID 1 e '$WP_PID1' (esperado: php-fpm8.2)"
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
# 8. WordPress usuários
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

### Executar Validação

```bash
# Dar permissão
chmod +x scripts/validate.sh

# Executar
./scripts/validate.sh
```

---

## 4. Problemas Comuns

### NGINX

#### "nginx: [emerg] bind() to 0.0.0.0:443 failed"

**Causa**: Porta 443 já em uso

```bash
# Verificar quem usa a porta
sudo lsof -i :443
sudo netstat -tlnp | grep 443

# Parar serviço conflitante
sudo systemctl stop apache2
sudo systemctl stop nginx
```

#### Certificado SSL inválido

**Causa**: Certificado não existe ou expirado

```bash
# Verificar certificado
docker exec nginx ls -la /etc/nginx/ssl/

# Regenerar
docker exec nginx /usr/local/bin/generate-ssl.sh

# Verificar validade
docker exec nginx openssl x509 -in /etc/nginx/ssl/inception.crt -noout -dates
```

#### "502 Bad Gateway"

**Causa**: Backend (WordPress) não está respondendo

```bash
# Verificar se WordPress está rodando
docker ps | grep wordpress

# Testar conexão interna
docker exec nginx ping -c 3 wordpress
docker exec nginx curl -v http://wordpress:9000/

# Ver logs do WordPress
docker logs wordpress
```

### MariaDB

#### "Access denied for user"

**Causa**: Senha incorreta ou usuário não existe

```bash
# Verificar variáveis de ambiente
docker exec mariadb env | grep MYSQL

# Testar conexão
docker exec mariadb mysql -u wpuser -p

# Verificar usuários
docker exec mariadb mysql -u root -p -e "SELECT User, Host FROM mysql.user;"
```

#### "Can't connect to MySQL server"

**Causa**: MariaDB ainda iniciando ou não está rodando

```bash
# Verificar status
docker exec mariadb mysqladmin ping -u root -p

# Ver logs
docker logs mariadb

# Verificar socket
docker exec mariadb ls -la /var/run/mysqld/
```

#### Dados perdidos após restart

**Causa**: Volume não configurado corretamente

```bash
# Verificar mounts
docker inspect mariadb --format '{{json .Mounts}}' | jq

# Verificar diretório host
ls -la /home/peda-cos/data/mariadb/
```

### WordPress

#### "Error establishing a database connection"

**Causa**: Configuração de banco incorreta

```bash
# Verificar wp-config.php
docker exec wordpress cat /var/www/html/wp-config.php | grep DB_

# Testar conexão do WordPress para MariaDB
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

# Verificar permissões
docker exec wordpress ls -la /var/www/html/
```

#### Plugins/Temas não instalam

**Causa**: Permissões de arquivo

```bash
# Corrigir permissões
docker exec wordpress chown -R www-data:www-data /var/www/html/wp-content/

# Verificar espaço em disco
docker exec wordpress df -h
```

### Docker Geral

#### "no space left on device"

**Causa**: Disco cheio

```bash
# Ver uso de disco Docker
docker system df

# Limpar imagens/containers não usados
docker system prune -a

# Limpar volumes não usados (CUIDADO!)
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

# Como root (se necessário)
docker exec -it --user root wordpress bash
```

### Inspecionar Container

```bash
# Informações completas
docker inspect nginx

# Informações específicas
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

# Árvore de processos
docker exec nginx pstree -p

# Top em tempo real
docker exec -it nginx top
```

### Verificar Arquivos de Configuração

```bash
# NGINX
docker exec nginx cat /etc/nginx/nginx.conf
docker exec nginx nginx -t

# PHP-FPM
docker exec wordpress cat /etc/php/8.2/fpm/php-fpm.conf
docker exec wordpress cat /etc/php/8.2/fpm/pool.d/www.conf

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

# Últimas N linhas
docker logs --tail 50 nginx

# Seguir em tempo real
docker logs -f nginx

# Com timestamps
docker logs -t nginx

# Desde horário específico
docker logs --since "2024-01-01T00:00:00" nginx
```

### Logs Combinados

```bash
# Via docker-compose
cd srcs
docker-compose logs -f

# Apenas alguns serviços
docker-compose logs -f nginx wordpress
```

### Estatísticas de Recursos

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

## 7. Perguntas da Avaliação

### Docker e Virtualização

**P: Qual a diferença entre VM e Container?**

R: VMs virtualizam hardware completo com hypervisor, cada uma com seu próprio OS. Containers compartilham o kernel do host, virtualizando apenas o userspace, sendo mais leves e rápidos.

**P: O que é uma imagem Docker?**

R: Template read-only com instruções para criar container. Composta de layers empilhadas, onde cada instrução do Dockerfile cria uma layer.

**P: O que é um container Docker?**

R: Instância executável de uma imagem. É a imagem em estado de execução, com uma layer de escrita no topo.

### Configuração

**P: Por que TLSv1.2/1.3 apenas?**

R: TLSv1.0 e 1.1 têm vulnerabilidades conhecidas (POODLE, BEAST). TLSv1.2+ são considerados seguros atualmente.

**P: Por que não usar `network: host`?**

R: `host` remove isolamento de rede, expõe todas as portas, e impede comunicação por nome de container. Redes customizadas oferecem isolamento e DNS interno.

**P: Por que usar volumes ao invés de bind mounts?**

R: Volumes são gerenciados pelo Docker, funcionam em qualquer OS, têm melhor performance, e podem ser facilmente backupeados.

**P: Por que não hardcodar senhas?**

R: Dockerfiles são versionados (git), imagens podem ser inspecionadas. Segredos devem vir de environment variables ou Docker Secrets.

### WordPress

**P: Por que 2 usuários?**

R: Demonstra que o sistema de usuários funciona. Um admin para gerenciar, outro para simular usuário comum.

**P: Por que admin não pode ter "admin" no nome?**

R: Segurança. Atacantes tentam "admin" primeiro em ataques de força bruta.

### Boas Práticas

**P: Por que `restart: unless-stopped`?**

R: Garante que serviços reiniciem após crashes ou reboots, mantendo alta disponibilidade.

**P: Por que não usar `tail -f /dev/null`?**

R: É um "hack" que mantém container vivo artificialmente. O daemon deveria rodar em foreground naturalmente.

**P: O que é PID 1 e por que importa?**

R: Primeiro processo do container. Responsável por repassar sinais (SIGTERM, etc.) e limpar processos zumbi. Deve ser o daemon principal.

### Dockerfiles e Imagens

**P: Por que não usar imagens prontas (nginx:latest, wordpress:latest)?**

R: O subject exige que você construa as imagens do zero para demonstrar entendimento. Imagens prontas escondem a configuração e não permitem personalização completa.

**P: Por que usar Debian Bullseye (penultimate stable)?**

R: O subject exige a penúltima versão estável. Bullseye é a penúltima (Bookworm é a atual). Isso garante estabilidade e compatibilidade.

**P: Por que não usar a tag :latest?**

R: A tag `latest` é mutável - pode mudar a qualquer momento. Isso causa builds não reproduzíveis e quebras inesperadas. Sempre especifique versões exatas.

**P: O que significa "build from scratch"?**

R: Começar da imagem base (Alpine/Debian) e instalar/configurar todos os pacotes manualmente. Não usar imagens com software pré-instalado.

### Networks e Comunicação

**P: Como os containers se comunicam entre si?**

R: Pelo nome do serviço (DNS interno do Docker). Ex: WordPress conecta ao MariaDB usando hostname `mariadb`. O Docker resolve internamente.

**P: Por que não usar --link?**

R: `--link` é deprecated. Docker networks oferecem DNS automático, isolamento, e não exigem ordem específica de start.

**P: Por que NGINX é o único ponto de entrada?**

R: Segurança. NGINX atua como reverse proxy, terminando TLS e encaminhando para backends internos. Reduz superfície de ataque.

### Volumes e Persistência

**P: O que acontece se eu deletar o container?**

R: Os dados persistem nos volumes. Containers são efêmeros; volumes são persistentes. Ao recriar o container, ele reconecta aos mesmos volumes.

**P: Por que os volumes ficam em /home/peda-cos/data/?**

R: Requisito do subject. Facilita backup e demonstra que dados persistem fora dos containers.

### PHP-FPM e WordPress

**P: Por que WordPress não tem NGINX dentro?**

R: Separação de responsabilidades. WordPress roda apenas PHP-FPM na porta 9000. NGINX é um container separado que encaminha requisições PHP.

**P: O que é PHP-FPM?**

R: FastCGI Process Manager. Gerencia processos PHP de forma eficiente. Escuta na porta 9000 e processa scripts PHP recebidos do NGINX.

**P: Por que wp-cli e não instalação manual?**

R: wp-cli permite automatizar instalação, criar usuários e configurar plugins via script. Essencial para setup não-interativo.

### Bonus - Redis

**P: Para que serve o Redis no WordPress?**

R: Cache de objetos. Armazena queries de banco em memória, reduzindo latência e carga no MariaDB. Melhora performance significativamente.

**P: Como verificar se Redis está funcionando?**

R: No admin do WordPress, o plugin Redis Object Cache mostra status "Connected". Também: `docker exec redis redis-cli ping` deve retornar "PONG".

### Bonus - FTP

**P: Por que o FTP aponta para o volume do WordPress?**

R: Permite upload de arquivos (temas, plugins) diretamente para wp-content via FTP, sem acessar o container.

### Segurança Geral

**P: O que são Docker Secrets?**

R: Mecanismo para passar dados sensíveis (senhas) para containers de forma segura. Montados como arquivos em /run/secrets/, não expostos como variáveis de ambiente.

**P: Por que usar secrets ao invés de variáveis de ambiente?**

R: Variáveis de ambiente podem ser expostas via `docker inspect` ou logs. Secrets são mais seguros, acessíveis apenas dentro do container.

---

## Comandos Rápidos para Avaliação

```bash
# Status geral
docker ps -a

# Verificar TLS
openssl s_client -connect peda-cos.42.fr:443 -tls1_2

# Verificar usuários WordPress
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

[Voltar ao Índice](00-INDICE.md) | [Anterior: Portainer](12-BONUS-PORTAINER.md) | [Próximo: Referências](14-REFERENCIAS.md)
