# Documentacao do Usuario - Inception

Guia de uso do sistema para usuarios finais.

---

## Indice

1. [Introducao](#introducao)
2. [Acessando o Sistema](#acessando-o-sistema)
3. [WordPress](#wordpress)
4. [Adminer](#adminer)
5. [Portfolio](#portfolio)
6. [Portainer](#portainer)
7. [FTP](#ftp)
8. [Solucao de Problemas](#solucao-de-problemas)

---

## Introducao

O Inception e uma infraestrutura web composta por varios servicos. Este guia explica como acessar e utilizar cada um deles.

### Servicos Disponiveis

| Servico   | URL                              | Descricao                     |
| --------- | -------------------------------- | ----------------------------- |
| WordPress | https://peda-cos.42.fr           | Blog/Site principal           |
| Adminer   | https://adminer.peda-cos.42.fr   | Gerenciador de banco de dados |
| Portfolio | https://static.peda-cos.42.fr    | Site estatico de portfolio    |
| Portainer | https://portainer.peda-cos.42.fr | Gerenciador de containers     |

---

## Acessando o Sistema

### Requisitos

- Navegador web moderno (Chrome, Firefox, Safari, Edge)
- Conexao com a rede onde o servidor esta hospedado
- Credenciais de acesso (fornecidas pelo administrador)

### Certificado SSL

O sistema utiliza certificados autoassinados. No primeiro acesso, voce vera um aviso de seguranca:

1. Clique em **"Avancado"** ou **"Mostrar detalhes"**
2. Clique em **"Continuar para o site"** ou **"Aceitar o risco"**
3. O navegador lembrara sua escolha

> **Nota:** Este aviso e normal para certificados autoassinados em ambiente de desenvolvimento.

---

## WordPress

### URL de Acesso

```
https://peda-cos.42.fr
```

### Login

1. Acesse `https://peda-cos.42.fr/wp-admin`
2. Insira seu usuario e senha
3. Clique em "Entrar"

### Painel Administrativo

Apos o login, voce tera acesso ao painel:

```
+----------------------------------------------------------+
|  Dashboard                                                |
+----------------------------------------------------------+
| Posts     | Todas as publicacoes do blog                 |
| Midia     | Biblioteca de imagens e arquivos             |
| Paginas   | Paginas estaticas do site                    |
| Aparencia | Temas e personalizacao                       |
| Plugins   | Extensoes do WordPress                       |
| Usuarios  | Gerenciamento de usuarios                    |
| Config.   | Configuracoes gerais do site                 |
+----------------------------------------------------------+
```

### Criando uma Publicacao

1. No menu lateral, clique em **"Posts"**
2. Clique em **"Adicionar Novo"**
3. Digite o titulo e conteudo
4. Clique em **"Publicar"**

### Enviando Midia

1. No menu lateral, clique em **"Midia"**
2. Clique em **"Adicionar Nova"**
3. Arraste arquivos ou clique para selecionar
4. Aguarde o upload completar

### Gerenciando Usuarios

> **Nota:** Apenas administradores podem gerenciar usuarios.

1. Va em **"Usuarios"** > **"Todos os Usuarios"**
2. Para adicionar: clique em **"Adicionar Novo"**
3. Preencha os dados e selecione o papel (role)
4. Clique em **"Adicionar Novo Usuario"**

#### Papeis de Usuario

| Papel         | Permissoes                                 |
| ------------- | ------------------------------------------ |
| Administrador | Acesso total ao sistema                    |
| Editor        | Pode publicar e editar todos os posts      |
| Autor         | Pode publicar e editar seus proprios posts |
| Colaborador   | Pode escrever, mas nao publicar            |
| Assinante     | Apenas visualizar conteudo                 |

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
   - **Usuario:** (fornecido pelo admin)
   - **Senha:** (fornecida pelo admin)
   - **Base de dados:** wordpress

3. Clique em **"Entrar"**

### Navegacao

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
2. Voce vera os dados em formato de tabela
3. Use os filtros para buscar registros especificos

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

> **Importante:** Faca backups regulares dos seus dados!

---

## Portfolio

### URL de Acesso

```
https://static.peda-cos.42.fr
```

### Sobre

O Portfolio e um site estatico que apresenta informacoes sobre o desenvolvedor. Nao requer login.

### Navegacao

- **Sobre:** Informacoes pessoais e biografia
- **Habilidades:** Tecnologias e competencias
- **Projetos:** Portfolio de trabalhos realizados
- **Contato:** Formulario e informacoes de contato

### Personalizacao

Para alterar o conteudo do portfolio, contate o desenvolvedor/administrador do sistema.

---

## Portainer

### URL de Acesso

```
https://portainer.peda-cos.42.fr
```

### Primeiro Acesso

No primeiro acesso, voce devera criar uma conta de administrador:

1. Acesse o Portainer
2. Defina um usuario e senha (minimo 12 caracteres)
3. Clique em **"Create user"**
4. Selecione **"Docker"** como ambiente
5. Clique em **"Connect"**

### Dashboard

```
+----------------------------------------------------------+
|  Portainer - Dashboard                                    |
+----------------------------------------------------------+
| Containers | Ver e gerenciar containers                  |
| Images     | Imagens Docker disponiveis                  |
| Volumes    | Volumes de dados                             |
| Networks   | Redes Docker                                 |
+----------------------------------------------------------+
```

### Gerenciando Containers

1. Clique em **"Containers"**
2. Voce vera a lista de todos os containers
3. Acoes disponiveis:
   - **Start/Stop:** Iniciar ou parar
   - **Restart:** Reiniciar
   - **Logs:** Ver logs do container
   - **Console:** Acessar terminal

### Visualizando Logs

1. Clique no nome do container
2. Clique em **"Logs"**
3. Opcoes:
   - Auto-refresh: Atualizar automaticamente
   - Timestamps: Mostrar data/hora
   - Lines: Numero de linhas

### Console do Container

1. Clique no nome do container
2. Clique em **"Console"**
3. Selecione o shell (`/bin/sh` ou `/bin/bash`)
4. Clique em **"Connect"**
5. Voce tera acesso ao terminal do container

---

## FTP

### Informacoes de Conexao

| Campo    | Valor                             |
| -------- | --------------------------------- |
| Servidor | peda-cos.42.fr                    |
| Porta    | 21                                |
| Usuario  | ftpuser (ou conforme configurado) |
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
   - Usuario: `ftpuser`
   - Senha: (sua senha)
   - Porta: `21`
3. Clique em **"Conexao Rapida"**

### Estrutura de Arquivos

```
/                          <- Raiz do FTP (wp-content)
├── themes/                <- Temas do WordPress
├── plugins/               <- Plugins
├── uploads/               <- Arquivos enviados
│   └── 2024/              <- Organizado por ano
│       └── 01/            <- E por mes
└── languages/             <- Arquivos de idioma
```

### Enviando Arquivos

1. Navegue ate a pasta desejada no servidor (lado direito)
2. Navegue ate a pasta local com seus arquivos (lado esquerdo)
3. Arraste os arquivos da esquerda para a direita
4. Aguarde a transferencia completar

### Baixando Arquivos

1. Navegue ate a pasta no servidor com os arquivos
2. Navegue ate a pasta local onde deseja salvar
3. Arraste os arquivos da direita para a esquerda

---

## Solucao de Problemas

### Nao Consigo Acessar o Site

**Problema:** Pagina nao carrega ou erro de conexao

**Solucoes:**

1. Verifique se digitou a URL corretamente
2. Verifique sua conexao com a internet
3. Limpe o cache do navegador (Ctrl+Shift+Delete)
4. Tente outro navegador
5. Contate o administrador

### Aviso de Certificado

**Problema:** Navegador mostra aviso de seguranca

**Solucao:**

- Isso e esperado com certificados autoassinados
- Clique em "Avancado" e aceite continuar
- Isso NAO significa que o site e inseguro

### Esqueci Minha Senha (WordPress)

**Problema:** Nao lembro a senha do WordPress

**Solucoes:**

1. Na tela de login, clique em **"Perdeu a senha?"**
2. Digite seu email ou usuario
3. Clique em **"Obter nova senha"**
4. Verifique seu email e siga as instrucoes

Se nao receber o email, contate o administrador.

### Erro ao Fazer Upload

**Problema:** Nao consigo enviar arquivos

**Possiveis causas:**

- Arquivo muito grande (limite: 64MB)
- Tipo de arquivo nao permitido
- Espaco em disco cheio

**Solucoes:**

1. Reduza o tamanho do arquivo
2. Converta para formato aceito (jpg, png, pdf)
3. Contate o administrador se persistir

### FTP Nao Conecta

**Problema:** Erro de conexao FTP

**Solucoes:**

1. Verifique usuario e senha
2. Confirme que esta usando modo passivo
3. Verifique se firewall nao esta bloqueando
4. Tente porta 21 especificamente

### Site Lento

**Problema:** Paginas demoram para carregar

**Solucoes:**

1. Limpe cache do navegador
2. Tente em outro horario
3. Verifique sua conexao de internet
4. Contate o administrador

---

## Contato e Suporte

Para problemas tecnicos ou duvidas, contate:

- **Administrador:** peda-cos
- **Email:** peda-cos@student.42sp.org.br

### Informacoes Uteis para Suporte

Ao reportar um problema, inclua:

- Qual servico esta com problema (WordPress, FTP, etc.)
- Qual acao estava tentando fazer
- Mensagem de erro exata (screenshot ajuda!)
- Navegador e versao que esta usando
- Horario aproximado do problema

---

_Documentacao do Usuario - Inception v1.0 - Janeiro 2026_
