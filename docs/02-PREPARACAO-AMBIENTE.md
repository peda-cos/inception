# 02 - Preparação do Ambiente

[Voltar ao Índice](./00-INDICE.md) | [Anterior: Fundamentos](./01-FUNDAMENTOS.md)

---

## Sumário

1. [Requisitos da Máquina Virtual](#1-requisitos-da-máquina-virtual)
2. [Instalação do Sistema Operacional](#2-instalação-do-sistema-operacional)
3. [Instalação do Docker](#3-instalação-do-docker)
4. [Instalação do Docker Compose](#4-instalação-do-docker-compose)
5. [Configuração do Usuário](#5-configuração-do-usuário)
6. [Configuração do Domínio Local](#6-configuração-do-domínio-local)
7. [Criação dos Diretórios de Dados](#7-criação-dos-diretórios-de-dados)
8. [Verificação Final](#8-verificação-final)

---

## 1. Requisitos da Máquina Virtual

O subject exige que o projeto seja feito em uma **Máquina Virtual**.

### Requisitos Mínimos Recomendados

| Recurso   | Mínimo        | Recomendado |
| --------- | ------------- | ----------- |
| **RAM**   | 2 GB          | 4 GB        |
| **CPU**   | 2 cores       | 4 cores     |
| **Disco** | 20 GB         | 40 GB       |
| **Rede**  | NAT ou Bridge | Bridge      |

### Softwares de Virtualização

- **VirtualBox** (gratuito) - Recomendado para 42
- **VMware Workstation/Fusion**
- **UTM** (para Mac M1/M2)
- **QEMU/KVM** (Linux)

### Configurações da VM no VirtualBox

```
1. Nova VM:
   - Nome: inception
   - Tipo: Linux
   - Versão: Debian (64-bit)

2. Memória: 4096 MB

3. Disco:
   - Criar disco virtual agora
   - VDI (VirtualBox Disk Image)
   - Dinamicamente alocado
   - 40 GB

4. Configurações adicionais:
   - Sistema > Processador: 2-4 CPUs
   - Rede > Adaptador 1: Bridge (recomendado) ou NAT
   - Armazenamento: Anexar ISO do Debian
```

---

## 2. Instalação do Sistema Operacional

Vamos usar **Debian 12 (Bookworm)** - a versão estável atual. Como estamos usando Debian Bullseye como base para os containers (penúltima estável), o host pode ser Bookworm.

### Download

- Site oficial: https://www.debian.org/download
- ISO recomendada: `debian-12.x.x-amd64-netinst.iso`

### Instalação

1. **Boot pela ISO**

2. **Instalação gráfica ou texto**
   - Idioma: Português (Brasil)
   - Localização: Brasil
   - Teclado: Português Brasileiro

3. **Configuração de rede**
   - Hostname: `inception`
   - Domínio: deixar em branco

4. **Usuários**
   - Senha root: (defina uma senha)
   - Nome completo: `peda-cos`
   - Login: `peda-cos`
   - Senha: (defina uma senha)

5. **Particionamento**
   - Usar disco inteiro
   - Todos os arquivos em uma partição

6. **Seleção de software**
   - Desmarque "Ambiente de desktop Debian"
   - Mantenha "Utilitários de sistema padrão"
   - Marque "Servidor SSH" (opcional, útil para acesso remoto)

7. **GRUB**
   - Instalar no disco principal

---

## 3. Instalação do Docker

Após reiniciar a VM, faça login como root ou use sudo.

### Passo 1: Atualizar o sistema

```bash
sudo apt update && sudo apt upgrade -y
```

### Passo 2: Instalar dependências

```bash
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

### Passo 3: Adicionar chave GPG do Docker

```bash
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/debian/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

### Passo 4: Adicionar repositório Docker

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Passo 5: Instalar Docker Engine

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Passo 6: Verificar instalação

```bash
sudo docker --version
# Docker version 24.x.x, build xxxxxxx

sudo docker run hello-world
# Deve exibir mensagem de sucesso
```

---

## 4. Instalação do Docker Compose

O Docker Compose v2 já vem incluído como plugin do Docker (instalado no passo anterior).

### Verificar instalação

```bash
docker compose version
# Docker Compose version v2.x.x
```

Se preferir usar o comando antigo `docker-compose`:

```bash
# Criar alias (opcional)
echo 'alias docker-compose="docker compose"' >> ~/.bashrc
source ~/.bashrc
```

---

## 5. Configuração do Usuário

### Adicionar usuário ao grupo docker

Para executar comandos Docker sem `sudo`:

```bash
sudo usermod -aG docker peda-cos
```

**IMPORTANTE**: Faça logout e login novamente para aplicar:

```bash
# Logout
exit

# Login novamente como peda-cos
```

### Verificar permissões

```bash
# Sem sudo deve funcionar agora
docker ps
```

Se ainda pedir senha, reinicie a VM:

```bash
sudo reboot
```

---

## 6. Configuração do Domínio Local

O subject exige que `peda-cos.42.fr` aponte para o IP local.

### Editar /etc/hosts

```bash
sudo nano /etc/hosts
```

Adicione a linha:

```
127.0.0.1	peda-cos.42.fr
```

O arquivo deve ficar assim:

```
127.0.0.1	localhost
127.0.0.1	peda-cos.42.fr

# IPv6
::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters
```

### Verificar configuração

```bash
ping -c 3 peda-cos.42.fr
```

Saída esperada:

```
PING peda-cos.42.fr (127.0.0.1) 56(84) bytes of data.
64 bytes from localhost (127.0.0.1): icmp_seq=1 ttl=64 time=0.028 ms
...
```

---

## 7. Criação dos Diretórios de Dados

O subject exige que os volumes estejam em `/home/peda-cos/data/`.

### Criar estrutura de diretórios

```bash
# Criar diretório principal
mkdir -p /home/peda-cos/data

# Criar subdiretórios para cada volume
mkdir -p /home/peda-cos/data/wordpress
mkdir -p /home/peda-cos/data/mariadb
```

### Verificar permissões

```bash
ls -la /home/peda-cos/data/
```

Saída esperada:

```
drwxr-xr-x 4 peda-cos peda-cos 4096 jan 10 12:00 .
drwxr-xr-x 5 peda-cos peda-cos 4096 jan 10 12:00 ..
drwxr-xr-x 2 peda-cos peda-cos 4096 jan 10 12:00 mariadb
drwxr-xr-x 2 peda-cos peda-cos 4096 jan 10 12:00 wordpress
```

### Definir propriedade correta

```bash
sudo chown -R peda-cos:peda-cos /home/peda-cos/data
```

---

## 8. Verificação Final

Execute este checklist para garantir que o ambiente está pronto:

### Script de Verificação

Crie e execute este script:

```bash
#!/bin/bash

echo "=== Verificação do Ambiente Inception ==="
echo ""

# Docker
echo "1. Docker Engine:"
if docker --version > /dev/null 2>&1; then
    docker --version
    echo "   [OK] Docker instalado"
else
    echo "   [ERRO] Docker não encontrado"
fi
echo ""

# Docker Compose
echo "2. Docker Compose:"
if docker compose version > /dev/null 2>&1; then
    docker compose version
    echo "   [OK] Docker Compose instalado"
else
    echo "   [ERRO] Docker Compose não encontrado"
fi
echo ""

# Usuário no grupo docker
echo "3. Usuário no grupo docker:"
if groups | grep -q docker; then
    echo "   [OK] Usuário está no grupo docker"
else
    echo "   [ERRO] Usuário não está no grupo docker"
fi
echo ""

# Domínio
echo "4. Domínio peda-cos.42.fr:"
if ping -c 1 peda-cos.42.fr > /dev/null 2>&1; then
    echo "   [OK] Domínio configurado corretamente"
else
    echo "   [ERRO] Domínio não responde"
fi
echo ""

# Diretórios de dados
echo "5. Diretórios de dados:"
if [ -d "/home/peda-cos/data/wordpress" ] && [ -d "/home/peda-cos/data/mariadb" ]; then
    echo "   [OK] Diretórios criados"
    ls -la /home/peda-cos/data/
else
    echo "   [ERRO] Diretórios não encontrados"
fi
echo ""

# Docker funcionando
echo "6. Docker funcionando:"
if docker run --rm hello-world > /dev/null 2>&1; then
    echo "   [OK] Docker executando containers"
else
    echo "   [ERRO] Docker não consegue executar containers"
fi
echo ""

echo "=== Verificação Concluída ==="
```

Salve como `check_env.sh` e execute:

```bash
chmod +x check_env.sh
./check_env.sh
```

### Resultado Esperado

Todos os itens devem mostrar `[OK]`:

```
=== Verificação do Ambiente Inception ===

1. Docker Engine:
Docker version 24.0.7, build afdd53b
   [OK] Docker instalado

2. Docker Compose:
Docker Compose version v2.21.0
   [OK] Docker Compose instalado

3. Usuário no grupo docker:
   [OK] Usuário está no grupo docker

4. Domínio peda-cos.42.fr:
   [OK] Domínio configurado corretamente

5. Diretórios de dados:
   [OK] Diretórios criados

6. Docker funcionando:
   [OK] Docker executando containers

=== Verificação Concluída ===
```

---

## Ferramentas Úteis (Opcional)

### Make

```bash
sudo apt install -y make
```

### Git

```bash
sudo apt install -y git
```

### Editor de texto

```bash
# Vim
sudo apt install -y vim

# Nano (já instalado por padrão)
# Ou instale outro de sua preferência
```

### OpenSSL (para testes de TLS)

```bash
sudo apt install -y openssl
```

### Curl

```bash
sudo apt install -y curl
```

---

## Problemas Comuns

### "Got permission denied while trying to connect to the Docker daemon"

```bash
# Adicione o usuário ao grupo docker
sudo usermod -aG docker $USER

# Faça logout e login novamente
exit
```

### Docker não inicia

```bash
# Verifique o status
sudo systemctl status docker

# Inicie o serviço
sudo systemctl start docker

# Habilite para iniciar com o sistema
sudo systemctl enable docker
```

### Sem espaço em disco

```bash
# Limpe imagens e containers não utilizados
docker system prune -a
```

---

## Próxima Etapa

Com o ambiente preparado, vamos criar a estrutura do projeto:

[Ir para 03-ESTRUTURA-PROJETO.md](./03-ESTRUTURA-PROJETO.md)
