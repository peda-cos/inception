# 14. Referências e Recursos

[Voltar ao Índice](00-INDICE.md) | [Anterior: Validação](13-VALIDACAO-TROUBLESHOOTING.md)

---

## Índice

1. [Documentação Oficial](#1-documentacao-oficial)
2. [Tutoriais e Guias](#2-tutoriais-e-guias)
3. [Ferramentas Úteis](#3-ferramentas-uteis)
4. [Livros Recomendados](#4-livros-recomendados)
5. [Comunidade](#5-comunidade)
6. [Projetos de Referência](#6-projetos-de-referencia)
7. [Vídeos e Cursos](#7-videos-e-cursos)
8. [Cheat Sheets](#8-cheat-sheets)
9. [Segurança](#9-seguranca)
10. [Uso de IA](#10-uso-de-ia)

---

## 1. Documentação Oficial

### Docker

| Recurso                  | Link                                                                      |
| ------------------------ | ------------------------------------------------------------------------- |
| Docker Documentation     | https://docs.docker.com/                                                  |
| Dockerfile Reference     | https://docs.docker.com/engine/reference/dockerfile/                      |
| Docker Compose Reference | https://docs.docker.com/compose/compose-file/                             |
| Docker CLI Reference     | https://docs.docker.com/engine/reference/commandline/cli/                 |
| Docker Networking        | https://docs.docker.com/network/                                          |
| Docker Volumes           | https://docs.docker.com/storage/volumes/                                  |
| Docker Secrets           | https://docs.docker.com/engine/swarm/secrets/                             |
| Best Practices           | https://docs.docker.com/develop/develop-images/dockerfile_best-practices/ |

### NGINX

| Recurso                | Link                                                               |
| ---------------------- | ------------------------------------------------------------------ |
| NGINX Documentation    | https://nginx.org/en/docs/                                         |
| NGINX Directives       | https://nginx.org/en/docs/dirindex.html                            |
| NGINX SSL/TLS          | https://nginx.org/en/docs/http/configuring_https_servers.html      |
| NGINX as Reverse Proxy | https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/ |

### MariaDB

| Recurso               | Link                                                               |
| --------------------- | ------------------------------------------------------------------ |
| MariaDB Documentation | https://mariadb.com/kb/en/documentation/                           |
| MariaDB Server        | https://mariadb.com/kb/en/mariadb-server/                          |
| MariaDB Docker        | https://mariadb.com/kb/en/installing-and-using-mariadb-via-docker/ |

### WordPress

| Recurso             | Link                                                                         |
| ------------------- | ---------------------------------------------------------------------------- |
| WordPress Developer | https://developer.wordpress.org/                                             |
| WP-CLI              | https://developer.wordpress.org/cli/commands/                                |
| WordPress Codex     | https://codex.wordpress.org/                                                 |
| wp-config.php       | https://developer.wordpress.org/advanced-administration/wordpress/wp-config/ |

### PHP-FPM

| Recurso           | Link                                            |
| ----------------- | ----------------------------------------------- |
| PHP-FPM           | https://www.php.net/manual/en/install.fpm.php   |
| PHP Configuration | https://www.php.net/manual/en/configuration.php |

---

## 2. Tutoriais e Guias

### Docker

- [Docker Getting Started](https://docs.docker.com/get-started/)
- [Play with Docker](https://labs.play-with-docker.com/)
- [Docker Curriculum](https://docker-curriculum.com/)
- [Docker Handbook](https://www.freecodecamp.org/news/the-docker-handbook/)

### NGINX + TLS

- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [NGINX SSL Termination](https://docs.nginx.com/nginx/admin-guide/security-controls/terminating-ssl-http/)

### WordPress + Docker

- [WordPress Docker Official](https://hub.docker.com/_/wordpress)
- [WP-CLI Handbook](https://make.wordpress.org/cli/handbook/)

---

## 3. Ferramentas Úteis

### Análise e Debug

| Ferramenta      | Descrição                        | Link                                        |
| --------------- | -------------------------------- | ------------------------------------------- |
| **dive**        | Analisa layers de imagens Docker | https://github.com/wagoodman/dive           |
| **ctop**        | Top-like para containers         | https://github.com/bcicen/ctop              |
| **lazydocker**  | TUI para gerenciar Docker        | https://github.com/jesseduffield/lazydocker |
| **docker-slim** | Otimiza imagens Docker           | https://github.com/docker-slim/docker-slim  |

### Validação

| Ferramenta   | Descrição                    | Link                                   |
| ------------ | ---------------------------- | -------------------------------------- |
| **hadolint** | Linter para Dockerfiles      | https://github.com/hadolint/hadolint   |
| **dockle**   | Security linter para imagens | https://github.com/goodwithtech/dockle |
| **trivy**    | Scanner de vulnerabilidades  | https://github.com/aquasecurity/trivy  |

### SSL/TLS

| Ferramenta     | Descrição                 | Link                                   |
| -------------- | ------------------------- | -------------------------------------- |
| **SSL Labs**   | Teste de configuração SSL | https://www.ssllabs.com/ssltest/       |
| **testssl.sh** | Script para testar TLS    | https://github.com/drwetter/testssl.sh |
| **mkcert**     | Cria certificados locais  | https://github.com/FiloSottile/mkcert  |

### Monitoramento

| Ferramenta     | Descrição                 | Link                      |
| -------------- | ------------------------- | ------------------------- |
| **Portainer**  | UI para gerenciar Docker  | https://www.portainer.io/ |
| **Prometheus** | Monitoramento e alertas   | https://prometheus.io/    |
| **Grafana**    | Dashboards e visualização | https://grafana.com/      |

---

## 4. Livros Recomendados

### Docker

1. **Docker Deep Dive** - Nigel Poulton
   - Excelente para entender Docker em profundidade
2. **Docker in Action** - Jeff Nickoloff
   - Abordagem prática com exemplos

3. **The Docker Book** - James Turnbull
   - Bom para iniciantes

### Linux e Sistemas

1. **Linux Command Line** - William Shotts
   - Essencial para entender comandos usados em containers
2. **How Linux Works** - Brian Ward
   - Entender o que acontece "por baixo"

### Segurança

1. **Docker Security** - Adrian Mouat
   - Práticas de segurança em containers

---

## 5. Comunidade

### Fóruns e Q&A

| Plataforma              | Link                                              |
| ----------------------- | ------------------------------------------------- |
| Stack Overflow - Docker | https://stackoverflow.com/questions/tagged/docker |
| Docker Community Forums | https://forums.docker.com/                        |
| Reddit r/docker         | https://www.reddit.com/r/docker/                  |
| Reddit r/devops         | https://www.reddit.com/r/devops/                  |

### Discord/Slack

| Comunidade             | Link                   |
| ---------------------- | ---------------------- |
| Docker Community Slack | https://dockr.ly/slack |
| CNCF Slack             | https://slack.cncf.io/ |

### 42 Específico

| Recurso      | Descrição                                              |
| ------------ | ------------------------------------------------------ |
| 42 Intra     | Recursos oficiais do projeto                           |
| Discord 42sp | Canal da comunidade brasileira                         |
| GitHub 42    | Repositórios de colegas (para referência, não copiar!) |

---

## 6. Projetos de Referência

### Arquiteturas Docker

```
# Estruturas de referência para aprender
https://github.com/docker/awesome-compose

# Exemplos oficiais Docker
https://github.com/docker/docker.github.io/tree/master/samples
```

### LEMP Stack (Linux, NGINX, MariaDB, PHP)

Projetos similares ao Inception que podem servir de inspiração:

- Docker LEMP Stack: https://github.com/stevenliebregt/docker-lemp
- Laradock: https://github.com/laradock/laradock

**IMPORTANTE**: Use apenas como referência para entender conceitos. O subject exige que você construa do zero!

---

## 7. Vídeos e Cursos

### YouTube - Docker

| Canal               | Conteúdo                 |
| ------------------- | ------------------------ |
| TechWorld with Nana | Docker Tutorial completo |
| NetworkChuck        | Docker para iniciantes   |
| Fireship            | Docker em 100 segundos   |
| Traversy Media      | Docker Crash Course      |

### Cursos Online

| Plataforma      | Curso                                |
| --------------- | ------------------------------------ |
| Docker Official | https://www.docker.com/101-tutorial/ |
| Udemy           | Docker Mastery (Bret Fisher)         |
| Linux Academy   | Docker Deep Dive                     |
| Coursera        | Containerized Applications on AWS    |

### Em Português

| Recurso     | Link                                |
| ----------- | ----------------------------------- |
| LinuxTips   | https://www.youtube.com/c/LinuxTips |
| Full Cycle  | https://www.youtube.com/c/FullCycle |
| Fabio Akita | Vídeos sobre Docker/DevOps          |

---

## 8. Cheat Sheets

### Docker

```bash
# Containers
docker ps                    # Lista containers rodando
docker ps -a                 # Lista todos os containers
docker run <image>           # Cria e inicia container
docker start <container>     # Inicia container parado
docker stop <container>      # Para container
docker rm <container>        # Remove container
docker logs <container>      # Vê logs
docker exec -it <c> sh       # Entra no container

# Imagens
docker images                # Lista imagens
docker build -t <name> .     # Constrói imagem
docker rmi <image>           # Remove imagem
docker pull <image>          # Baixa imagem

# Volumes
docker volume ls             # Lista volumes
docker volume create <name>  # Cria volume
docker volume rm <name>      # Remove volume

# Networks
docker network ls            # Lista networks
docker network create <name> # Cria network
docker network inspect <n>   # Inspeciona network

# Limpeza
docker system prune          # Remove recursos não usados
docker system prune -a       # Remove TUDO não usado
```

### Docker Compose

```bash
docker-compose up             # Inicia serviços
docker-compose up -d          # Inicia em background
docker-compose up --build     # Rebuild e inicia
docker-compose down           # Para e remove
docker-compose down -v        # Remove volumes também
docker-compose logs           # Vê logs
docker-compose logs -f        # Segue logs
docker-compose ps             # Lista serviços
docker-compose exec <s> sh    # Entra no serviço
docker-compose build          # Apenas build
docker-compose pull           # Atualiza imagens
```

### NGINX

```bash
nginx -t                      # Testa configuração
nginx -s reload               # Recarrega config
nginx -s stop                 # Para NGINX
nginx -V                      # Mostra versão e módulos
```

### MariaDB/MySQL

```bash
mysql -u root -p              # Conecta como root
mysqladmin ping               # Testa se está rodando
mysqldump <db> > backup.sql   # Backup
mysql <db> < backup.sql       # Restore
```

### WP-CLI

```bash
wp core download              # Baixa WordPress
wp core install               # Instala WordPress
wp user list                  # Lista usuários
wp user create <u> <e>        # Cria usuário
wp plugin list                # Lista plugins
wp plugin install <p>         # Instala plugin
wp theme list                 # Lista temas
wp cache flush                # Limpa cache
wp db check                   # Verifica banco
```

---

## 9. Segurança

### Recursos de Segurança

| Recurso                        | Link                                                                            |
| ------------------------------ | ------------------------------------------------------------------------------- |
| OWASP Docker Security          | https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html |
| CIS Docker Benchmark           | https://www.cisecurity.org/benchmark/docker                                     |
| Snyk Container Security        | https://snyk.io/learn/container-security/                                       |
| Docker Security Best Practices | https://docs.docker.com/develop/security-best-practices/                        |

### Checklist de Segurança

- [ ] Não rodar containers como root
- [ ] Usar imagens base mínimas (Alpine)
- [ ] Escanear imagens com Trivy/Snyk
- [ ] Não expor Docker socket
- [ ] Usar secrets ao invés de env vars para senhas
- [ ] Manter imagens atualizadas
- [ ] Limitar recursos (CPU, memória)
- [ ] Usar read-only filesystem quando possível
- [ ] Não usar `--privileged`
- [ ] Implementar health checks

---

## 10. Uso de IA

### Ferramentas de IA Utilizadas

Este projeto utilizou as seguintes ferramentas de IA como assistentes:

| Ferramenta             | Uso                                                                              |
| ---------------------- | -------------------------------------------------------------------------------- |
| **Claude (Anthropic)** | Assistente principal para geração de documentação, código e explicações técnicas |

### Como a IA foi Utilizada

1. **Geração de Documentação**
   - Criação da estrutura do tutorial
   - Redação de explicações técnicas
   - Formatação Markdown

2. **Código e Configuração**
   - Dockerfiles com boas práticas
   - Scripts de inicialização
   - Configurações NGINX, PHP-FPM, MariaDB
   - Docker Compose completo

3. **Troubleshooting**
   - Identificação de problemas comuns
   - Sugestões de soluções
   - Scripts de validação

4. **Revisão e Melhoria**
   - Verificação de conformidade com o subject
   - Sugestões de segurança
   - Otimizações de código

### Considerações sobre Uso de IA

**O que a IA fez bem:**

- Estruturar conteúdo de forma organizada
- Explicar conceitos complexos de forma clara
- Gerar código funcional seguindo boas práticas
- Identificar potenciais problemas

**O que ainda requer atenção humana:**

- Testar todo o código em ambiente real
- Validar configurações para seu caso específico
- Adaptar senhas e credenciais
- Verificar compatibilidade de versões

### Transparência

Conforme solicitado pelo subject da 42, esta seção documenta o uso de IA generativa no desenvolvimento do projeto. O código e documentação foram gerados com assistência de IA, mas devem ser:

1. **Compreendidos** - Você deve entender cada linha
2. **Testados** - Executar e validar em seu ambiente
3. **Adaptados** - Ajustar para suas necessidades
4. **Defendidos** - Ser capaz de explicar na avaliação

---

## Links Rápidos

### Documentação do Projeto

| Arquivo                                                            | Conteúdo                 |
| ------------------------------------------------------------------ | ------------------------ |
| [00-INDICE.md](00-INDICE.md)                                       | Índice geral e checklist |
| [01-FUNDAMENTOS.md](01-FUNDAMENTOS.md)                             | Teoria Docker            |
| [02-PREPARACAO-AMBIENTE.md](02-PREPARACAO-AMBIENTE.md)             | Setup VM e Docker        |
| [03-ESTRUTURA-PROJETO.md](03-ESTRUTURA-PROJETO.md)                 | Organização de arquivos  |
| [04-MARIADB.md](04-MARIADB.md)                                     | Container de banco       |
| [05-WORDPRESS.md](05-WORDPRESS.md)                                 | Container WordPress      |
| [06-NGINX.md](06-NGINX.md)                                         | Container NGINX + TLS    |
| [07-DOCKER-COMPOSE.md](07-DOCKER-COMPOSE.md)                       | Orquestração             |
| [08-BONUS-REDIS.md](08-BONUS-REDIS.md)                             | Cache Redis              |
| [09-BONUS-FTP.md](09-BONUS-FTP.md)                                 | Servidor FTP             |
| [10-BONUS-ADMINER.md](10-BONUS-ADMINER.md)                         | Gerenciador de BD        |
| [11-BONUS-SITE-ESTATICO.md](11-BONUS-SITE-ESTATICO.md)             | Portfólio estático       |
| [12-BONUS-PORTAINER.md](12-BONUS-PORTAINER.md)                     | Gerenciador Docker       |
| [13-VALIDACAO-TROUBLESHOOTING.md](13-VALIDACAO-TROUBLESHOOTING.md) | Testes e debug           |

---

**Boa sorte no projeto Inception!**

Se tiver dúvidas, consulte a documentação oficial, pergunte aos colegas, ou utilize a IA como ferramenta de aprendizado (não apenas para copiar código).

---

[Voltar ao Índice](00-INDICE.md) | [Anterior: Validação](13-VALIDACAO-TROUBLESHOOTING.md)
