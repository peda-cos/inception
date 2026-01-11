_Este projeto foi desenvolvido como parte do curriculo da 42 Sao Paulo, utilizando Docker para criar uma infraestrutura completa de servicos web._

# Inception

Infraestrutura Docker para hospedar WordPress com NGINX, MariaDB e servicos bonus, implementando boas praticas de containerizacao, seguranca e automacao.

---

## Descricao

O projeto Inception consiste em configurar uma pequena infraestrutura composta por diferentes servicos usando Docker e Docker Compose. Cada servico roda em um container dedicado, construido a partir de Dockerfiles customizados baseados em Debian Bullseye.

### Arquitetura

```
                    +-------------+
                    |   Cliente   |
                    |  (Browser)  |
                    +------+------+
                           |
                           | HTTPS (443)
                           v
                    +------+------+
                    |    NGINX    |
                    | TLSv1.2/1.3 |
                    +------+------+
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
    +-----------+    +-----------+    +-----------+
    | WordPress |    |   Redis   |    |   Static  |
    |  PHP-FPM  |    |   Cache   |    |   Site    |
    +-----+-----+    +-----------+    +-----------+
          |
          v
    +-----------+
    |  MariaDB  |
    +-----------+
```

### Servicos Implementados

| Servico         | Descricao             | Porta Interna   |
| --------------- | --------------------- | --------------- |
| **NGINX**       | Servidor web com TLS  | 443             |
| **WordPress**   | CMS com PHP-FPM       | 9000            |
| **MariaDB**     | Banco de dados        | 3306            |
| **Redis**       | Cache de objetos      | 6379            |
| **FTP**         | Servidor de arquivos  | 21, 21000-21010 |
| **Adminer**     | Gerenciador de BD     | 8080            |
| **Static Site** | Portfolio HTML/CSS/JS | 8081            |
| **Portainer**   | Gerenciador Docker    | 9000            |

---

## Instrucoes

### Pre-requisitos

- Virtual Machine com Debian/Ubuntu
- Docker Engine 20.10+
- Docker Compose 2.0+
- 4GB RAM minimo
- 20GB espaco em disco

### Instalacao

1. **Clonar o repositorio:**

   ```bash
   git clone <repository-url> inception
   cd inception
   ```

2. **Configurar secrets:**

   ```bash
   mkdir -p secrets
   echo "sua_senha_root_mysql" > secrets/db_root_password.txt
   echo "sua_senha_usuario_mysql" > secrets/db_password.txt
   echo "usuario_wp:senha_wp" > secrets/credentials.txt
   echo "sua_senha_ftp" > secrets/ftp_password.txt
   chmod 600 secrets/*
   ```

3. **Configurar dominio (hosts):**

   ```bash
   echo "127.0.0.1 peda-cos.42.fr" | sudo tee -a /etc/hosts
   echo "127.0.0.1 www.peda-cos.42.fr" | sudo tee -a /etc/hosts
   echo "127.0.0.1 adminer.peda-cos.42.fr" | sudo tee -a /etc/hosts
   echo "127.0.0.1 static.peda-cos.42.fr" | sudo tee -a /etc/hosts
   echo "127.0.0.1 portainer.peda-cos.42.fr" | sudo tee -a /etc/hosts
   ```

4. **Criar diretorios de dados:**

   ```bash
   mkdir -p /home/peda-cos/data/{wordpress,mariadb,redis,portainer}
   ```

5. **Construir e iniciar:**

   ```bash
   make
   ```

6. **Acessar:**
   - WordPress: https://peda-cos.42.fr
   - Adminer: https://adminer.peda-cos.42.fr
   - Portfolio: https://static.peda-cos.42.fr
   - Portainer: https://portainer.peda-cos.42.fr

### Comandos Disponiveis

```bash
make          # Build e inicia todos os containers
make build    # Apenas build das imagens
make up       # Inicia containers existentes
make down     # Para containers
make clean    # Remove containers e imagens
make fclean   # Remove tudo (incluindo volumes)
make re       # Rebuild completo
make logs     # Ver logs de todos os servicos
make status   # Ver status dos containers
```

---

## Recursos

### Comparacoes Tecnicas

#### Maquinas Virtuais vs Docker Containers

| Aspecto           | Maquina Virtual       | Container Docker          |
| ----------------- | --------------------- | ------------------------- |
| **Virtualizacao** | Hardware (hypervisor) | SO (kernel compartilhado) |
| **Tamanho**       | GBs (OS completo)     | MBs (apenas app + deps)   |
| **Inicializacao** | Minutos               | Segundos                  |
| **Isolamento**    | Completo              | Nivel de processo         |
| **Overhead**      | Alto (RAM, CPU)       | Baixo                     |
| **Portabilidade** | Limitada              | Alta (imagens)            |
| **Densidade**     | ~10-20 por host       | ~100s por host            |

**Quando usar VMs:**

- Isolamento completo necessario
- Diferentes sistemas operacionais
- Aplicacoes legadas

**Quando usar Containers:**

- Microservicos
- CI/CD pipelines
- Ambientes de desenvolvimento
- Escalabilidade horizontal

#### Docker Secrets vs Environment Variables

| Aspecto           | Environment Variables  | Docker Secrets             |
| ----------------- | ---------------------- | -------------------------- |
| **Armazenamento** | Em memoria, visivel    | Encriptado em disco        |
| **Acesso**        | `docker inspect` expoe | Apenas dentro do container |
| **Gerenciamento** | Manual                 | Via Docker/Swarm           |
| **Rotacao**       | Requer restart         | Pode ser atualizado        |
| **Auditoria**     | Dificil                | Logs disponiveis           |

**Recomendacao:** Use secrets para senhas, tokens, certificados. Use env vars para configuracoes nao-sensiveis.

#### Docker Network vs Host Network

| Aspecto         | Network Customizada  | Host Network   |
| --------------- | -------------------- | -------------- |
| **Isolamento**  | Completo             | Nenhum         |
| **DNS interno** | Sim (por nome)       | Nao            |
| **Portas**      | Mapeamento explicito | Todas expostas |
| **Seguranca**   | Alta                 | Baixa          |
| **Performance** | Minimo overhead      | Sem overhead   |

**Recomendacao:** Sempre use networks customizadas exceto para casos muito especificos de performance.

#### Docker Volumes vs Bind Mounts

| Aspecto           | Volumes                    | Bind Mounts         |
| ----------------- | -------------------------- | ------------------- |
| **Gerenciamento** | Docker gerencia            | Usuario gerencia    |
| **Localizacao**   | `/var/lib/docker/volumes/` | Qualquer path       |
| **Portabilidade** | Alta                       | Depende do host     |
| **Performance**   | Otimizada                  | Varia               |
| **Backup**        | `docker volume` commands   | Ferramentas do host |
| **Permissoes**    | Gerenciadas                | Podem conflitar     |

**Recomendacao:** Use volumes para dados de aplicacao, bind mounts para desenvolvimento.

### Uso de IA

Este projeto utilizou ferramentas de IA como assistentes no desenvolvimento:

| Ferramenta             | Uso                                              |
| ---------------------- | ------------------------------------------------ |
| **Claude (Anthropic)** | Geracao de documentacao, codigo, troubleshooting |

A IA foi utilizada para:

- Gerar estrutura de Dockerfiles seguindo boas praticas
- Criar scripts de inicializacao
- Escrever documentacao tecnica
- Identificar e resolver problemas comuns

**Importante:** Todo codigo gerado foi revisado, testado e adaptado. O desenvolvedor e capaz de explicar cada componente.

### Documentacao Adicional

- [Tutorial Completo](docs/00-INDICE.md)
- [Documentacao do Usuario](USER_DOC.md)
- [Documentacao do Desenvolvedor](DEV_DOC.md)

### Referencias Externas

- [Docker Documentation](https://docs.docker.com/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [WordPress Developer](https://developer.wordpress.org/)
- [WP-CLI](https://developer.wordpress.org/cli/commands/)

---

## Autor

**peda-cos** - 42 Sao Paulo

---

## Licenca

Este projeto foi desenvolvido para fins educacionais como parte do curriculo da 42.
