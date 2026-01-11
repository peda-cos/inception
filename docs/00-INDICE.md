# Inception - Tutorial Completo

## 42 São Paulo - peda-cos

---

## Sobre Este Tutorial

Este tutorial foi criado para guiar você na construção completa do projeto **Inception** da 42, desde os conceitos fundamentais até o deploy final, incluindo todos os bônus.

**Login:** peda-cos  
**Domínio:** peda-cos.42.fr  
**Campus:** 42sp - São Paulo/Brasil  
**Base Image:** Debian Bullseye (penúltima versão estável)

---

## Índice Geral

### Parte Obrigatória

| #   | Documento                                             | Descrição                                               | Status |
| --- | ----------------------------------------------------- | ------------------------------------------------------- | ------ |
| 01  | [Fundamentos](./01-FUNDAMENTOS.md)                    | Teoria Docker, VMs vs Containers, conceitos essenciais  | [ ]    |
| 02  | [Preparação do Ambiente](./02-PREPARACAO-AMBIENTE.md) | Setup da VM, instalação Docker, configuração de domínio | [ ]    |
| 03  | [Estrutura do Projeto](./03-ESTRUTURA-PROJETO.md)     | Makefile, .env, secrets, diretórios                     | [ ]    |
| 04  | [MariaDB](./04-MARIADB.md)                            | Container de banco de dados                             | [ ]    |
| 05  | [WordPress](./05-WORDPRESS.md)                        | Container WordPress + PHP-FPM                           | [ ]    |
| 06  | [NGINX](./06-NGINX.md)                                | Container NGINX com TLS                                 | [ ]    |
| 07  | [Docker Compose](./07-DOCKER-COMPOSE.md)              | Orquestração completa dos serviços                      | [ ]    |

### Parte Bônus

| #   | Documento                                    | Descrição                                   | Status |
| --- | -------------------------------------------- | ------------------------------------------- | ------ |
| 08  | [Redis Cache](./08-BONUS-REDIS.md)           | Cache para WordPress                        | [ ]    |
| 09  | [FTP Server](./09-BONUS-FTP.md)              | Servidor FTP para arquivos WordPress        | [ ]    |
| 10  | [Adminer](./10-BONUS-ADMINER.md)             | Interface web para gerenciar banco de dados | [ ]    |
| 11  | [Site Estático](./11-BONUS-SITE-ESTATICO.md) | Site de apresentação/currículo              | [ ]    |
| 12  | [Portainer](./12-BONUS-PORTAINER.md)         | Gerenciamento visual de containers          | [ ]    |

### Validação e Recursos

| #   | Documento                                                        | Descrição                                  |
| --- | ---------------------------------------------------------------- | ------------------------------------------ |
| 13  | [Validação e Troubleshooting](./13-VALIDACAO-TROUBLESHOOTING.md) | Testes, checklist e resolução de problemas |
| 14  | [Referências](./14-REFERENCIAS.md)                               | Documentação e recursos adicionais         |

---

## Ordem de Implementação Recomendada

```
┌─────────────────────────────────────────────────────────────────┐
│                    FASE 1: PREPARAÇÃO                           │
├─────────────────────────────────────────────────────────────────┤
│  01-FUNDAMENTOS → 02-PREPARACAO-AMBIENTE → 03-ESTRUTURA-PROJETO │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    FASE 2: SERVIÇOS BASE                        │
├─────────────────────────────────────────────────────────────────┤
│              04-MARIADB → 05-WORDPRESS → 06-NGINX               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    FASE 3: ORQUESTRAÇÃO                         │
├─────────────────────────────────────────────────────────────────┤
│                       07-DOCKER-COMPOSE                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    FASE 4: VALIDAÇÃO                            │
├─────────────────────────────────────────────────────────────────┤
│                 13-VALIDACAO-TROUBLESHOOTING                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    FASE 5: BÔNUS (opcional)                     │
├─────────────────────────────────────────────────────────────────┤
│     08-REDIS → 09-FTP → 10-ADMINER → 11-SITE → 12-PORTAINER     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Estrutura Final do Projeto

```
inception/
├── Makefile
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── docker-compose.yml
    ├── .env
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        └── bonus/
            ├── redis/
            ├── ftp/
            ├── adminer/
            ├── static-site/
            └── portainer/
```

---

## Checklist de Progresso

### Obrigatório

- [ ] VM configurada com Docker e Docker Compose
- [ ] Estrutura de diretórios criada
- [ ] Makefile funcional
- [ ] Arquivo .env configurado
- [ ] Docker Secrets configurados
- [ ] Container MariaDB funcionando
- [ ] Container WordPress + PHP-FPM funcionando
- [ ] Container NGINX com TLS funcionando
- [ ] Volumes persistentes configurados
- [ ] Rede Docker customizada
- [ ] Domínio peda-cos.42.fr configurado
- [ ] Dois usuários WordPress criados (sem "admin" no nome)
- [ ] Containers reiniciam automaticamente em caso de crash
- [ ] README.md completo
- [ ] USER_DOC.md completo
- [ ] DEV_DOC.md completo

### Bônus

- [ ] Redis Cache integrado ao WordPress
- [ ] Servidor FTP apontando para volume WordPress
- [ ] Adminer para gerenciamento do banco
- [ ] Site estático (sem PHP)
- [ ] Portainer para gestão de containers

---

## Dicas Importantes

1. **Leia cada seção completamente** antes de começar a implementar
2. **Teste cada container individualmente** antes de integrá-los
3. **Nunca use a tag `latest`** - sempre especifique versões
4. **Nunca coloque senhas no Dockerfile** - use .env ou secrets
5. **Evite "hacky patches"** como `tail -f`, `sleep infinity`, `while true`
6. **Use `exec` nos entrypoints** para gerenciamento correto do PID 1
7. **Teste o TLS** com `openssl s_client` antes da avaliação

---

## Suporte

Se encontrar problemas, consulte:

- [13-VALIDACAO-TROUBLESHOOTING.md](./13-VALIDACAO-TROUBLESHOOTING.md) para soluções comuns
- [14-REFERENCIAS.md](./14-REFERENCIAS.md) para documentação oficial

---

_Boa sorte com o Inception!_
