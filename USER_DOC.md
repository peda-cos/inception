# Documentação do Usuário - Inception

Guia de uso do sistema para usuários finais.

---

## Índice

1. [Introdução](#introdução)
2. [Acessando o Sistema](#acessando-o-sistema)
3. [WordPress](#wordpress)
4. [Adminer](#adminer)
5. [Portfólio](#portfólio)
6. [Portainer](#portainer)
7. [FTP](#ftp)
8. [Solução de Problemas](#solução-de-problemas)

---

## Introdução

O Inception é uma infraestrutura web composta por vários serviços. Este guia explica como acessar e utilizar cada um deles.

### Serviços Disponíveis

| Serviço   | URL                              | Descrição                     |
| --------- | -------------------------------- | ----------------------------- |
| WordPress | https://peda-cos.42.fr           | Blog/Site principal           |
| Adminer   | https://adminer.peda-cos.42.fr   | Gerenciador de banco de dados |
| Portfólio | https://static.peda-cos.42.fr    | Site estático de portfólio    |
| Portainer | https://portainer.peda-cos.42.fr | Gerenciador de containers     |

---

## Acessando o Sistema

### Requisitos

- Navegador web moderno (Chrome, Firefox, Safari, Edge)
- Conexão com a rede onde o servidor está hospedado
- Credenciais de acesso (fornecidas pelo administrador)

### Certificado SSL

O sistema utiliza certificados autoassinados. No primeiro acesso, você verá um aviso de segurança:

1. Clique em **"Avançado"** ou **"Mostrar detalhes"**
2. Clique em **"Continuar para o site"** ou **"Aceitar o risco"**
3. O navegador lembrará sua escolha

> **Nota:** Este aviso é normal para certificados autoassinados em ambiente de desenvolvimento.

---

## WordPress

### URL de Acesso

```
https://peda-cos.42.fr
```

### Login

1. Acesse `https://peda-cos.42.fr/wp-admin`
2. Insira seu usuário e senha
3. Clique em "Entrar"

### Painel Administrativo

Após o login, você terá acesso ao painel:

```
+----------------------------------------------------------+
|  Dashboard                                                |
+----------------------------------------------------------+
| Posts     | Todas as publicações do blog                 |
| Mídia     | Biblioteca de imagens e arquivos             |
| Páginas   | Páginas estáticas do site                    |
| Aparência | Temas e personalização                       |
| Plugins   | Extensões do WordPress                       |
| Usuários  | Gerenciamento de usuários                    |
| Config.   | Configurações gerais do site                 |
+----------------------------------------------------------+
```

### Criando uma Publicação

1. No menu lateral, clique em **"Posts"**
2. Clique em **"Adicionar Novo"**
3. Digite o título e conteúdo
4. Clique em **"Publicar"**

### Enviando Mídia

1. No menu lateral, clique em **"Mídia"**
2. Clique em **"Adicionar Nova"**
3. Arraste arquivos ou clique para selecionar
4. Aguarde o upload completar

### Gerenciando Usuários

> **Nota:** Apenas administradores podem gerenciar usuários.

1. Vá em **"Usuários"** > **"Todos os Usuários"**
2. Para adicionar: clique em **"Adicionar Novo"**
3. Preencha os dados e selecione o papel (role)
4. Clique em **"Adicionar Novo Usuário"**

#### Papéis de Usuário

| Papel         | Permissões                                 |
| ------------- | ------------------------------------------ |
| Administrador | Acesso total ao sistema                    |
| Editor        | Pode publicar e editar todos os posts      |
| Autor         | Pode publicar e editar seus próprios posts |
| Colaborador   | Pode escrever, mas não publicar            |
| Assinante     | Apenas visualizar conteúdo                 |

---

## Adminer

### URL de Acesso

```
https://adminer.peda-cos.42.fr
```

### Login

1. Acesse o Adminer
2. Preencha os campos:
   - **Sistema:** MySQL
   - **Servidor:** mariadb
   - **Usuário:** (fornecido pelo admin)
   - **Senha:** (fornecida pelo admin)
   - **Base de dados:** wordpress

3. Clique em **"Entrar"**

### Navegação

```
+----------------------------------------------------------+
|  Adminer - wordpress                                      |
+----------------------------------------------------------+
| Banco de dados | Selecionar outro banco                   |
| SQL            | Executar consultas SQL                   |
| Exportar       | Fazer backup dos dados                   |
| Importar       | Restaurar backup                         |
| Tabelas        | Lista de tabelas do banco                |
+----------------------------------------------------------+
```

### Visualizando Dados

1. Clique no nome da tabela desejada
2. Você verá os dados em formato de tabela
3. Use os filtros para buscar registros específicos

### Executando SQL

1. Clique em **"SQL"** no menu
2. Digite sua consulta SQL
3. Clique em **"Executar"**

**Exemplo:**

```sql
SELECT * FROM wp_users;
```

### Fazendo Backup

1. Clique em **"Exportar"**
2. Selecione as tabelas desejadas
3. Escolha o formato (SQL recomendado)
4. Clique em **"Exportar"**
5. Salve o arquivo baixado

> **Importante:** Faça backups regulares dos seus dados!

---

## Portfólio

### URL de Acesso

```
https://static.peda-cos.42.fr
```

### Sobre

O Portfólio é um site estático que apresenta informações sobre o desenvolvedor. Não requer login.

### Navegação

- **Sobre:** Informações pessoais e biografia
- **Habilidades:** Tecnologias e competências
- **Projetos:** Portfólio de trabalhos realizados
- **Contato:** Formulário e informações de contato

### Personalização

Para alterar o conteúdo do portfólio, contate o desenvolvedor/administrador do sistema.

---

## Portainer

### URL de Acesso

```
https://portainer.peda-cos.42.fr
```

### Primeiro Acesso

No primeiro acesso, você deverá criar uma conta de administrador:

1. Acesse o Portainer
2. Defina um usuário e senha (mínimo 12 caracteres)
3. Clique em **"Create user"**
4. Selecione **"Docker"** como ambiente
5. Clique em **"Connect"**

### Dashboard

```
+----------------------------------------------------------+
|  Portainer - Dashboard                                    |
+----------------------------------------------------------+
| Containers | Ver e gerenciar containers                  |
| Images     | Imagens Docker disponíveis                  |
| Volumes    | Volumes de dados                             |
| Networks   | Redes Docker                                 |
+----------------------------------------------------------+
```

### Gerenciando Containers

1. Clique em **"Containers"**
2. Você verá a lista de todos os containers
3. Ações disponíveis:
   - **Start/Stop:** Iniciar ou parar
   - **Restart:** Reiniciar
   - **Logs:** Ver logs do container
   - **Console:** Acessar terminal

### Visualizando Logs

1. Clique no nome do container
2. Clique em **"Logs"**
3. Opções:
   - Auto-refresh: Atualizar automaticamente
   - Timestamps: Mostrar data/hora
   - Lines: Número de linhas

### Console do Container

1. Clique no nome do container
2. Clique em **"Console"**
3. Selecione o shell (`/bin/sh` ou `/bin/bash`)
4. Clique em **"Connect"**
5. Você terá acesso ao terminal do container

---

## FTP

### Informações de Conexão

| Campo    | Valor                             |
| -------- | --------------------------------- |
| Servidor | peda-cos.42.fr                    |
| Porta    | 21                                |
| Usuário  | ftpuser (ou conforme configurado) |
| Senha    | (fornecida pelo admin)            |
| Modo     | Passivo                           |

### Clientes FTP Recomendados

- **FileZilla** (Windows, Mac, Linux)
- **Cyberduck** (Mac, Windows)
- **WinSCP** (Windows)

### Conectando com FileZilla

1. Abra o FileZilla
2. Preencha:
   - Host: `peda-cos.42.fr`
   - Usuário: `ftpuser`
   - Senha: (sua senha)
   - Porta: `21`
3. Clique em **"Conexão Rápida"**

### Estrutura de Arquivos

```
/                          <- Raiz do FTP (wp-content)
├── themes/                <- Temas do WordPress
├── plugins/               <- Plugins
├── uploads/               <- Arquivos enviados
│   └── 2024/              <- Organizado por ano
│       └── 01/            <- E por mês
└── languages/             <- Arquivos de idioma
```

### Enviando Arquivos

1. Navegue até a pasta desejada no servidor (lado direito)
2. Navegue até a pasta local com seus arquivos (lado esquerdo)
3. Arraste os arquivos da esquerda para a direita
4. Aguarde a transferência completar

### Baixando Arquivos

1. Navegue até a pasta no servidor com os arquivos
2. Navegue até a pasta local onde deseja salvar
3. Arraste os arquivos da direita para a esquerda

---

## Solução de Problemas

### Não Consigo Acessar o Site

**Problema:** Página não carrega ou erro de conexão

**Soluções:**

1. Verifique se digitou a URL corretamente
2. Verifique sua conexão com a internet
3. Limpe o cache do navegador (Ctrl+Shift+Delete)
4. Tente outro navegador
5. Contate o administrador

### Aviso de Certificado

**Problema:** Navegador mostra aviso de segurança

**Solução:**

- Isso é esperado com certificados autoassinados
- Clique em "Avançado" e aceite continuar
- Isso NÃO significa que o site é inseguro

### Esqueci Minha Senha (WordPress)

**Problema:** Não lembro a senha do WordPress

**Soluções:**

1. Na tela de login, clique em **"Perdeu a senha?"**
2. Digite seu email ou usuário
3. Clique em **"Obter nova senha"**
4. Verifique seu email e siga as instruções

Se não receber o email, contate o administrador.

### Erro ao Fazer Upload

**Problema:** Não consigo enviar arquivos

**Possíveis causas:**

- Arquivo muito grande (limite: 64MB)
- Tipo de arquivo não permitido
- Espaço em disco cheio

**Soluções:**

1. Reduza o tamanho do arquivo
2. Converta para formato aceito (jpg, png, pdf)
3. Contate o administrador se persistir

### FTP Não Conecta

**Problema:** Erro de conexão FTP

**Soluções:**

1. Verifique usuário e senha
2. Confirme que está usando modo passivo
3. Verifique se firewall não está bloqueando
4. Tente porta 21 especificamente

### Site Lento

**Problema:** Páginas demoram para carregar

**Soluções:**

1. Limpe cache do navegador
2. Tente em outro horário
3. Verifique sua conexão de internet
4. Contate o administrador

---

## Contato e Suporte

Para problemas técnicos ou dúvidas, contate:

- **Administrador:** peda-cos
- **Email:** peda-cos@student.42sp.org.br

### Informações Úteis para Suporte

Ao reportar um problema, inclua:

- Qual serviço está com problema (WordPress, FTP, etc.)
- Qual ação estava tentando fazer
- Mensagem de erro exata (screenshot ajuda!)
- Navegador e versão que está usando
- Horário aproximado do problema

---

_Documentação do Usuário - Inception v1.0 - Janeiro 2026_
