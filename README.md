_Este projeto foi desenvolvido como parte do currículo da 42 São Paulo, utilizando Docker para criar uma infraestrutura completa de serviços web._

# Inception

Infraestrutura Docker para hospedar WordPress com NGINX, MariaDB e serviços bônus, implementando boas práticas de containerização, segurança e automação.

---

## Descrição

O projeto Inception consiste em configurar uma pequena infraestrutura composta por diferentes serviços usando Docker e Docker Compose. Cada serviço roda em um container dedicado, construído a partir de Dockerfiles customizados baseados em Debian Bullseye.

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

### Serviços Implementados

| Serviço         | Descrição            | Porta Interna   |
| --------------- | -------------------- | --------------- |
| **NGINX**       | Servidor web com TLS | 443             |
| **WordPress**   | CMS com PHP-FPM      | 9000            |
| **MariaDB**     | Banco de dados       | 3306            |
| **Redis**       | Cache de objetos     | 6379            |
| **FTP**         | Servidor de arquivos | 21, 21000-21010 |
| **Adminer**     | Gerenciador de BD    | 8080            |
| **Static Site** | Portfólio HTML/CSS   | 8081            |
| **Portainer**   | Gerenciador Docker   | 9000            |

---

## Instruções

### Pré-requisitos

- Virtual Machine com Debian/Ubuntu
- Docker Engine 20.10+
- Docker Compose 2.0+
- 4GB RAM mínimo
- 20GB espaço em disco

### Instalação

1. **Clonar o repositório:**

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

3. **Configurar domínio (hosts):**

   ```bash
   echo "127.0.0.1 peda-cos.42.fr" | sudo tee -a /etc/hosts
   echo "127.0.0.1 www.peda-cos.42.fr" | sudo tee -a /etc/hosts
   echo "127.0.0.1 adminer.peda-cos.42.fr" | sudo tee -a /etc/hosts
   echo "127.0.0.1 static.peda-cos.42.fr" | sudo tee -a /etc/hosts
   echo "127.0.0.1 portainer.peda-cos.42.fr" | sudo tee -a /etc/hosts
   ```

4. **Criar diretórios de dados:**

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
   - Portfólio: https://static.peda-cos.42.fr
   - Portainer: https://portainer.peda-cos.42.fr

### Comandos Disponíveis

```bash
make          # Build e inicia todos os containers
make build    # Apenas build das imagens
make up       # Inicia containers existentes
make down     # Para containers
make clean    # Remove containers e imagens
make fclean   # Remove tudo (incluindo volumes)
make re       # Rebuild completo
make logs     # Ver logs de todos os serviços
make status   # Ver status dos containers
```

---

## Recursos

### Comparações Técnicas

#### Máquinas Virtuais vs Docker Containers

| Aspecto           | Máquina Virtual       | Container Docker          |
| ----------------- | --------------------- | ------------------------- |
| **Virtualização** | Hardware (hypervisor) | SO (kernel compartilhado) |
| **Tamanho**       | GBs (OS completo)     | MBs (apenas app + deps)   |
| **Inicialização** | Minutos               | Segundos                  |
| **Isolamento**    | Completo              | Nível de processo         |
| **Overhead**      | Alto (RAM, CPU)       | Baixo                     |
| **Portabilidade** | Limitada              | Alta (imagens)            |
| **Densidade**     | ~10-20 por host       | ~100s por host            |

**Quando usar VMs:**

- Isolamento completo necessário
- Diferentes sistemas operacionais
- Aplicações legadas

**Quando usar Containers:**

- Microsserviços
- CI/CD pipelines
- Ambientes de desenvolvimento
- Escalabilidade horizontal

#### Docker Secrets vs Environment Variables

| Aspecto           | Environment Variables  | Docker Secrets             |
| ----------------- | ---------------------- | -------------------------- |
| **Armazenamento** | Em memória, visível    | Encriptado em disco        |
| **Acesso**        | `docker inspect` expõe | Apenas dentro do container |
| **Gerenciamento** | Manual                 | Via Docker/Swarm           |
| **Rotação**       | Requer restart         | Pode ser atualizado        |
| **Auditoria**     | Difícil                | Logs disponíveis           |

**Recomendação:** Use secrets para senhas, tokens, certificados. Use env vars para configurações não-sensíveis.

#### Docker Network vs Host Network

| Aspecto         | Network Customizada  | Host Network   |
| --------------- | -------------------- | -------------- |
| **Isolamento**  | Completo             | Nenhum         |
| **DNS interno** | Sim (por nome)       | Não            |
| **Portas**      | Mapeamento explícito | Todas expostas |
| **Segurança**   | Alta                 | Baixa          |
| **Performance** | Mínimo overhead      | Sem overhead   |

**Recomendação:** Sempre use networks customizadas exceto para casos muito específicos de performance.

#### Docker Volumes vs Bind Mounts

| Aspecto           | Volumes                    | Bind Mounts         |
| ----------------- | -------------------------- | ------------------- |
| **Gerenciamento** | Docker gerencia            | Usuário gerencia    |
| **Localização**   | `/var/lib/docker/volumes/` | Qualquer path       |
| **Portabilidade** | Alta                       | Depende do host     |
| **Performance**   | Otimizada                  | Varia               |
| **Backup**        | `docker volume` commands   | Ferramentas do host |
| **Permissões**    | Gerenciadas                | Podem conflitar     |

**Recomendação:** Use volumes para dados de aplicação, bind mounts para desenvolvimento.

### Uso de IA

Este projeto utilizou ferramentas de IA como assistentes no desenvolvimento:

| Ferramenta             | Uso                                              |
| ---------------------- | ------------------------------------------------ |
| **Claude (Anthropic)** | Geração de documentação, código, troubleshooting |

A IA foi utilizada para:

- Gerar estrutura de Dockerfiles seguindo boas práticas
- Criar scripts de inicialização
- Escrever documentação técnica
- Identificar e resolver problemas comuns

**Importante:** Todo código gerado foi revisado, testado e adaptado. O desenvolvedor é capaz de explicar cada componente.

### Documentação Adicional

- [Tutorial Completo](docs/00-INDICE.md)
- [Documentação do Usuário](USER_DOC.md)
- [Documentação do Desenvolvedor](DEV_DOC.md)

### Referências Externas

- [Docker Documentation](https://docs.docker.com/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [WordPress Developer](https://developer.wordpress.org/)
- [WP-CLI](https://developer.wordpress.org/cli/commands/)

---

## Autor

**peda-cos** - 42 São Paulo

---

## Licença

Este projeto foi desenvolvido para fins educacionais como parte do currículo da 42.
