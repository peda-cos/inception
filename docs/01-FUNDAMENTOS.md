# 01 - Fundamentos de Docker e Containerização

[Voltar ao Índice](./00-INDICE.md)

---

## Sumário

1. [O que é Docker?](#1-o-que-é-docker)
2. [Máquinas Virtuais vs Containers](#2-máquinas-virtuais-vs-containers)
3. [Arquitetura Docker](#3-arquitetura-docker)
4. [Conceitos Essenciais](#4-conceitos-essenciais)
5. [Docker Compose](#5-docker-compose)
6. [PID 1 e Gerenciamento de Processos](#6-pid-1-e-gerenciamento-de-processos)
7. [Comparações Técnicas Importantes](#7-comparações-técnicas-importantes)
8. [Regras do Subject](#8-regras-do-subject)

---

## 1. O que é Docker?

Docker é uma plataforma de **containerização** que permite empacotar aplicações e suas dependências em unidades isoladas chamadas **containers**. Diferente de máquinas virtuais, containers compartilham o kernel do sistema operacional host, tornando-os mais leves e eficientes.

### Por que usar Docker no Inception?

1. **Isolamento**: Cada serviço (NGINX, WordPress, MariaDB) roda em seu próprio ambiente
2. **Reprodutibilidade**: O mesmo container funciona em qualquer máquina
3. **Portabilidade**: Fácil de mover entre ambientes de desenvolvimento e produção
4. **Eficiência**: Containers são mais leves que VMs tradicionais

---

## 2. Máquinas Virtuais vs Containers

Esta é uma das comparações **obrigatórias** do README conforme o subject.

### Diagrama Comparativo

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        MÁQUINAS VIRTUAIS                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                      │
│  │    App A    │  │    App B    │  │    App C    │                      │
│  ├─────────────┤  ├─────────────┤  ├─────────────┤                      │
│  │   Bins/Libs │  │   Bins/Libs │  │   Bins/Libs │                      │
│  ├─────────────┤  ├─────────────┤  ├─────────────┤                      │
│  │  Guest OS   │  │  Guest OS   │  │  Guest OS   │  ← SO completo       │
│  │  (Linux)    │  │  (Windows)  │  │  (Linux)    │    em cada VM        │
│  └─────────────┘  └─────────────┘  └─────────────┘                      │
│  ┌─────────────────────────────────────────────────┐                    │
│  │              HYPERVISOR (VMware, VirtualBox)    │                    │
│  └─────────────────────────────────────────────────┘                    │
│  ┌─────────────────────────────────────────────────┐                    │
│  │                    HOST OS                      │                    │
│  └─────────────────────────────────────────────────┘                    │
│  ┌─────────────────────────────────────────────────┐                    │
│  │                   HARDWARE                      │                    │
│  └─────────────────────────────────────────────────┘                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                           CONTAINERS                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                      │
│  │    App A    │  │    App B    │  │    App C    │                      │
│  ├─────────────┤  ├─────────────┤  ├─────────────┤                      │
│  │   Bins/Libs │  │   Bins/Libs │  │   Bins/Libs │  ← Apenas libs       │
│  └─────────────┘  └─────────────┘  └─────────────┘    necessárias       │
│  ┌─────────────────────────────────────────────────┐                    │
│  │              DOCKER ENGINE                      │                    │
│  └─────────────────────────────────────────────────┘                    │
│  ┌─────────────────────────────────────────────────┐                    │
│  │              HOST OS (Linux Kernel)             │  ← Kernel          │
│  └─────────────────────────────────────────────────┘    compartilhado   │
│  ┌─────────────────────────────────────────────────┐                    │
│  │                   HARDWARE                      │                    │
│  └─────────────────────────────────────────────────┘                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Tabela Comparativa

| Aspecto           | Máquinas Virtuais               | Containers Docker               |
| ----------------- | ------------------------------- | ------------------------------- |
| **Isolamento**    | Completo (hardware virtual)     | Nível de processo (namespaces)  |
| **Tamanho**       | GBs (inclui SO completo)        | MBs (apenas app e dependências) |
| **Startup**       | Minutos                         | Segundos                        |
| **Performance**   | Overhead do hypervisor          | Próximo ao nativo               |
| **Recursos**      | Alto consumo de RAM/CPU         | Baixo consumo                   |
| **Portabilidade** | Limitada (imagens grandes)      | Alta (imagens leves)            |
| **Kernel**        | Próprio por VM                  | Compartilhado com host          |
| **Uso**           | Múltiplos SOs, isolamento total | Microserviços, DevOps           |

### Quando usar cada um?

**Use VMs quando:**

- Precisa rodar diferentes sistemas operacionais
- Requer isolamento completo de hardware
- Aplicações legadas que precisam de ambiente específico

**Use Containers quando:**

- Microserviços e arquiteturas modernas
- CI/CD e DevOps
- Escalabilidade horizontal
- Desenvolvimento consistente entre ambientes

---

## 3. Arquitetura Docker

### Componentes Principais

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENTE DOCKER                              │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  docker build    docker pull    docker run    docker compose │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  │ REST API
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         DOCKER DAEMON (dockerd)                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │   Images     │  │  Containers  │  │   Networks   │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
│  ┌──────────────┐  ┌──────────────┐                                 │
│  │   Volumes    │  │   Plugins    │                                 │
│  └──────────────┘  └──────────────┘                                 │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         CONTAINER RUNTIME                           │
│                      (containerd + runc)                            │
└─────────────────────────────────────────────────────────────────────┘
```

### Fluxo de Criação de um Container

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Dockerfile  │ ──► │    Image     │ ──► │  Container   │
│  (instruções)│     │  (template)  │     │  (instância) │
└──────────────┘     └──────────────┘     └──────────────┘
     docker            docker run           Aplicação
     build             ou compose           rodando
```

---

## 4. Conceitos Essenciais

### 4.1 Dockerfile

Um Dockerfile é um arquivo de texto com instruções para construir uma imagem Docker.

```dockerfile
FROM debian:oldstable

WORKDIR /app

COPY ./src /app

RUN apt-get update && apt-get install -y nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### Instruções Principais do Dockerfile

| Instrução    | Descrição                    | Exemplo                     |
| ------------ | ---------------------------- | --------------------------- |
| `FROM`       | Imagem base                  | `FROM debian:oldstable`     |
| `WORKDIR`    | Define diretório de trabalho | `WORKDIR /var/www`          |
| `COPY`       | Copia arquivos do host       | `COPY ./conf /etc/nginx`    |
| `ADD`        | Copia + extrai arquivos      | `ADD app.tar.gz /app`       |
| `RUN`        | Executa comando no build     | `RUN apt-get update`        |
| `ENV`        | Define variável de ambiente  | `ENV NODE_ENV=production`   |
| `ARG`        | Argumento de build           | `ARG VERSION=1.0`           |
| `EXPOSE`     | Documenta porta              | `EXPOSE 443`                |
| `VOLUME`     | Define ponto de montagem     | `VOLUME /var/lib/mysql`     |
| `USER`       | Define usuário               | `USER www-data`             |
| `ENTRYPOINT` | Comando fixo                 | `ENTRYPOINT ["nginx"]`      |
| `CMD`        | Comando padrão               | `CMD ["-g", "daemon off;"]` |

### 4.2 Imagens Docker

Imagens são templates read-only compostos por camadas (layers).

```
┌─────────────────────────────────────┐
│            CONTAINER                │  ← Camada de escrita
│         (writable layer)            │
├─────────────────────────────────────┤
│      CMD ["nginx", "-g", "..."]     │  ← Layer 4
├─────────────────────────────────────┤
│      COPY ./conf /etc/nginx         │  ← Layer 3
├─────────────────────────────────────┤
│      RUN apt-get install nginx      │  ← Layer 2
├─────────────────────────────────────┤
│      FROM debian:oldstable          │  ← Layer 1 (base)
└─────────────────────────────────────┘
```

### 4.3 Containers

Container é uma **instância em execução** de uma imagem.

```bash
# Criar e executar um container
docker run -d --name nginx nginx:1.24

# Listar containers em execução
docker ps

# Ver logs
docker logs nginx

# Executar comando dentro do container
docker exec -it nginx sh

# Parar container
docker stop nginx

# Remover container
docker rm nginx
```

### 4.4 Volumes

Volumes são o mecanismo preferido para persistir dados gerados por containers.

```bash
# Criar volume nomeado
docker volume create wordpress_data

# Usar volume em container
docker run -v wordpress_data:/var/www/html wordpress

# Listar volumes
docker volume ls

# Inspecionar volume
docker volume inspect wordpress_data
```

### 4.5 Redes

Redes Docker permitem comunicação entre containers.

```bash
# Criar rede
docker network create inception_network

# Conectar container à rede
docker run --network inception_network nginx

# Listar redes
docker network ls
```

---

## 5. Docker Compose

Docker Compose é uma ferramenta para definir e executar aplicações multi-container.

### Estrutura Básica do docker-compose.yml

```yaml
version: "3.8"

services:
  nginx:
    build: ./requirements/nginx
    container_name: nginx
    ports:
      - "443:443"
    networks:
      - inception
    volumes:
      - wordpress_data:/var/www/html
    depends_on:
      - wordpress
    restart: unless-stopped

  wordpress:
    build: ./requirements/wordpress
    container_name: wordpress
    networks:
      - inception
    volumes:
      - wordpress_data:/var/www/html
    environment:
      - WORDPRESS_DB_HOST=mariadb
    depends_on:
      - mariadb
    restart: unless-stopped

  mariadb:
    build: ./requirements/mariadb
    container_name: mariadb
    networks:
      - inception
    volumes:
      - db_data:/var/lib/mysql
    restart: unless-stopped

networks:
  inception:
    driver: bridge

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

### Comandos Docker Compose

```bash
# Construir imagens
docker-compose build

# Iniciar serviços
docker-compose up -d

# Ver logs
docker-compose logs -f

# Parar serviços
docker-compose down

# Parar e remover volumes
docker-compose down -v

# Reconstruir e iniciar
docker-compose up -d --build
```

---

## 6. PID 1 e Gerenciamento de Processos

Este é um conceito **crítico** para o Inception. O subject proíbe explicitamente "hacky patches".

### O que é PID 1?

Em sistemas Unix/Linux, o **PID 1** é o primeiro processo iniciado. Em containers Docker, o processo definido no `CMD` ou `ENTRYPOINT` se torna o PID 1.

### Responsabilidades do PID 1

1. **Receber sinais do sistema** (SIGTERM, SIGINT, etc.)
2. **Repassar sinais para processos filhos**
3. **Limpar processos zumbis (reaping)**
4. **Encerrar graciosamente quando solicitado**

### Por que NÃO usar hacky patches?

O subject proíbe:

- `tail -f`
- `bash`
- `sleep infinity`
- `while true`

**Motivos:**

1. **Não respondem a sinais corretamente**

   ```bash
   # RUIM: tail não repassa SIGTERM para outros processos
   CMD ["tail", "-f", "/dev/null"]
   ```

2. **Criam processos zumbis**

   ```bash
   # RUIM: bash não faz reaping de processos filhos
   CMD ["bash", "-c", "nginx & sleep infinity"]
   ```

3. **Dificultam restart e health checks**
   ```bash
   # RUIM: Container nunca "falha" mesmo se serviço morrer
   CMD ["sh", "-c", "while true; do sleep 1; done"]
   ```

### Solução Correta: Executar daemon em foreground

```dockerfile
# CORRETO: nginx é o PID 1 e responde a sinais
CMD ["nginx", "-g", "daemon off;"]
```

```dockerfile
# CORRETO: php-fpm é o PID 1
CMD ["php-fpm", "-F"]
```

```dockerfile
# CORRETO: mysqld é o PID 1
CMD ["mysqld", "--user=mysql"]
```

### Uso do `exec` em Entrypoints

Quando usar scripts de entrypoint, use `exec` para **substituir** o shell pelo processo principal:

```bash
#!/bin/sh
set -e

# Configurações iniciais
echo "Inicializando..."

# exec substitui o shell pelo processo (que vira PID 1)
exec nginx -g "daemon off;"
```

**Sem `exec`:**

```
PID 1: /bin/sh (script)
  └── PID 2: nginx
```

**Com `exec`:**

```
PID 1: nginx (recebe sinais diretamente)
```

---

## 7. Comparações Técnicas Importantes

Estas comparações são **obrigatórias** no README conforme o subject.

### 7.1 Secrets vs Environment Variables

| Aspecto           | Environment Variables          | Docker Secrets                  |
| ----------------- | ------------------------------ | ------------------------------- |
| **Armazenamento** | Em memória do container        | Em arquivos no container        |
| **Visibilidade**  | `docker inspect` expõe valores | Não visíveis via inspect        |
| **Uso**           | `$VARIAVEL`                    | Leitura de arquivo              |
| **Segurança**     | Menor (podem vazar em logs)    | Maior (criptografados em swarm) |
| **Recomendação**  | Dados não sensíveis            | Senhas, chaves, tokens          |

**Environment Variables:**

```yaml
# docker-compose.yml
services:
  wordpress:
    environment:
      - WORDPRESS_DB_HOST=mariadb
      - WORDPRESS_DB_NAME=wordpress
```

**Docker Secrets:**

```yaml
# docker-compose.yml
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

### 7.2 Docker Network vs Host Network

| Aspecto         | Docker Network (bridge) | Host Network             |
| --------------- | ----------------------- | ------------------------ |
| **Isolamento**  | Containers isolados     | Compartilha rede do host |
| **Comunicação** | Via nomes de container  | Via localhost            |
| **Portas**      | Mapeamento explícito    | Acesso direto            |
| **Segurança**   | Maior (rede isolada)    | Menor (exposição)        |
| **Inception**   | **OBRIGATÓRIO**         | **PROIBIDO**             |

**Docker Network (Correto):**

```yaml
services:
  nginx:
    networks:
      - inception

networks:
  inception:
    driver: bridge
```

**Host Network (PROIBIDO no Inception):**

```yaml
# NÃO FAZER - proibido pelo subject
services:
  nginx:
    network_mode: host
```

### 7.3 Docker Volumes vs Bind Mounts

| Aspecto           | Docker Volumes             | Bind Mounts                |
| ----------------- | -------------------------- | -------------------------- |
| **Gerenciamento** | Pelo Docker                | Pelo usuário               |
| **Localização**   | `/var/lib/docker/volumes/` | Qualquer caminho           |
| **Backup**        | Via comandos Docker        | Backup direto do diretório |
| **Portabilidade** | Alta                       | Depende do caminho         |
| **Performance**   | Otimizado                  | Depende do FS              |
| **Inception**     | Usado com driver local     | Requerido pelo subject     |

**No Inception**, usamos volumes nomeados com driver local apontando para `/home/peda-cos/data/`:

```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/peda-cos/data/wordpress
```

---

## 8. Regras do Subject

### O que é OBRIGATÓRIO:

- [ ] Projeto rodando em VM
- [ ] Usar docker-compose
- [ ] Cada serviço em container dedicado
- [ ] Imagens baseadas em Debian ou Alpine (penúltima versão estável)
- [ ] Escrever próprios Dockerfiles
- [ ] Containers reiniciam em caso de crash
- [ ] NGINX como único ponto de entrada (porta 443)
- [ ] TLSv1.2 ou TLSv1.3 apenas
- [ ] Volumes em `/home/peda-cos/data/`
- [ ] Domínio `peda-cos.42.fr` apontando para IP local
- [ ] Dois usuários WordPress (admin sem "admin" no nome)
- [ ] Usar variáveis de ambiente
- [ ] Usar .env para armazenar variáveis
- [ ] README.md, USER_DOC.md, DEV_DOC.md

### O que é PROIBIDO:

- [ ] Usar tag `latest`
- [ ] Senhas nos Dockerfiles
- [ ] Usar imagens prontas do DockerHub (exceto base)
- [ ] Usar `network: host`
- [ ] Usar `--link` ou `links:`
- [ ] Usar `tail -f`, `sleep infinity`, `while true`, `bash` como comando principal
- [ ] Credenciais expostas no repositório Git

---

## Próxima Etapa

Agora que você entende os fundamentos, vamos preparar o ambiente de desenvolvimento:

[Ir para 02-PREPARACAO-AMBIENTE.md](./02-PREPARACAO-AMBIENTE.md)
