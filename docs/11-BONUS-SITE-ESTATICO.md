# 11 - Bônus: Site Estático

[Voltar ao Índice](./00-INDICE.md) | [Anterior: Adminer](./10-BONUS-ADMINER.md)

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Dockerfile](#2-dockerfile)
3. [Página HTML](#3-página-html)
4. [Estilos CSS](#4-estilos-css)
5. [Docker Compose](#5-docker-compose)
6. [Testes e Validação](#6-testes-e-validação)

---

## 1. Visão Geral

O subject pede um site estático em **qualquer linguagem exceto PHP**. Vamos criar um site de apresentação/currículo usando:

- HTML5
- CSS3
- JavaScript (vanilla)

### Arquivos a Criar

```
srcs/requirements/bonus/static-site/
├── Dockerfile
├── .dockerignore
├── conf/
│   └── nginx.conf
└── www/
    ├── index.html
    ├── style.css
    └── script.js
```

---

## 2. Dockerfile

### srcs/requirements/bonus/static-site/Dockerfile

```dockerfile
# ============================================================================ #
#                          STATIC SITE DOCKERFILE                              #
#                                                                              #
#  Base: Debian Bullseye (penúltima versão estável)                           #
#  Serviço: NGINX servindo site estático                                       #
# ============================================================================ #

FROM debian:bullseye

# Instalar NGINX e utilitários
# curl: necessário para healthcheck
# procps: necessário para verificação de PID 1 (ps)
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Criar diretórios
RUN mkdir -p /var/www/static \
    && mkdir -p /run/nginx

# Copiar arquivos do site
COPY www/ /var/www/static/

# Copiar configuração NGINX
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Ajustar permissões
RUN chown -R www-data:www-data /var/www/static

# Expor porta
EXPOSE 8081

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8081/ || exit 1

# Iniciar NGINX
CMD ["nginx", "-g", "daemon off;"]
```

### srcs/requirements/bonus/static-site/conf/nginx.conf

```nginx
# ============================================================================ #
#                     NGINX - STATIC SITE CONFIGURATION                        #
# ============================================================================ #

user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 512;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    keepalive_timeout 65;
    server_tokens off;

    server {
        listen 8081;
        listen [::]:8081;

        server_name _;

        root /var/www/static;
        index index.html;

        location / {
            try_files $uri $uri/ =404;
        }

        # Cache para arquivos estáticos
        location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

---

## 3. Página HTML

### srcs/requirements/bonus/static-site/www/index.html

```html
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta
      name="description"
      content="Portfolio de peda-cos - Estudante 42 São Paulo"
    />
    <title>peda-cos | 42 São Paulo</title>
    <link rel="stylesheet" href="style.css" />
  </head>
  <body>
    <div class="container">
      <!-- Header -->
      <header class="header">
        <nav class="nav">
          <div class="logo">peda-cos</div>
          <ul class="nav-links">
            <li><a href="#about">Sobre</a></li>
            <li><a href="#skills">Skills</a></li>
            <li><a href="#projects">Projetos</a></li>
            <li><a href="#contact">Contato</a></li>
          </ul>
        </nav>
      </header>

      <!-- Hero Section -->
      <section class="hero">
        <div class="hero-content">
          <h1>Olá, eu sou <span class="highlight">peda-cos</span></h1>
          <p class="subtitle">Estudante de programação na 42 São Paulo</p>
          <p class="description">
            Apaixonado por tecnologia, desenvolvimento de software e resolução
            de problemas complexos.
          </p>
          <a href="#projects" class="cta-button">Ver Projetos</a>
        </div>
        <div class="hero-image">
          <div class="terminal">
            <div class="terminal-header">
              <span class="dot red"></span>
              <span class="dot yellow"></span>
              <span class="dot green"></span>
            </div>
            <div class="terminal-body">
              <p><span class="prompt">$</span> whoami</p>
              <p class="output">peda-cos</p>
              <p><span class="prompt">$</span> cat skills.txt</p>
              <p class="output">C, Shell, Docker, Git</p>
              <p><span class="prompt">$</span> echo "42 SP"</p>
              <p class="output">42 SP</p>
              <p><span class="prompt">$</span> <span class="cursor">_</span></p>
            </div>
          </div>
        </div>
      </section>

      <!-- About Section -->
      <section id="about" class="section">
        <h2>Sobre Mim</h2>
        <div class="about-content">
          <p>
            Sou estudante na <strong>42 São Paulo</strong>, uma escola de
            programação inovadora baseada em aprendizado peer-to-peer. Estou
            constantemente buscando novos desafios e oportunidades de
            crescimento.
          </p>
          <p>
            Este site foi criado como parte do projeto
            <strong>Inception</strong>, demonstrando conhecimentos em Docker,
            containerização e infraestrutura.
          </p>
        </div>
      </section>

      <!-- Skills Section -->
      <section id="skills" class="section">
        <h2>Habilidades</h2>
        <div class="skills-grid">
          <div class="skill-card">
            <div class="skill-icon">C</div>
            <h3>Linguagem C</h3>
            <p>Programação de baixo nível, gerenciamento de memória</p>
          </div>
          <div class="skill-card">
            <div class="skill-icon">$_</div>
            <h3>Shell/Bash</h3>
            <p>Scripts, automação, administração de sistemas</p>
          </div>
          <div class="skill-card">
            <div class="skill-icon">D</div>
            <h3>Docker</h3>
            <p>Containerização, Docker Compose, DevOps</p>
          </div>
          <div class="skill-card">
            <div class="skill-icon">G</div>
            <h3>Git</h3>
            <p>Controle de versão, colaboração, workflows</p>
          </div>
        </div>
      </section>

      <!-- Projects Section -->
      <section id="projects" class="section">
        <h2>Projetos</h2>
        <div class="projects-grid">
          <div class="project-card">
            <h3>Inception</h3>
            <p>Infraestrutura Docker com NGINX, WordPress e MariaDB</p>
            <div class="tags">
              <span>Docker</span>
              <span>NGINX</span>
              <span>TLS</span>
            </div>
          </div>
          <div class="project-card">
            <h3>Libft</h3>
            <p>Biblioteca C com funções padrão reimplementadas</p>
            <div class="tags">
              <span>C</span>
              <span>Makefile</span>
            </div>
          </div>
          <div class="project-card">
            <h3>ft_printf</h3>
            <p>Reimplementação da função printf</p>
            <div class="tags">
              <span>C</span>
              <span>Variadic</span>
            </div>
          </div>
        </div>
      </section>

      <!-- Contact Section -->
      <section id="contact" class="section">
        <h2>Contato</h2>
        <div class="contact-info">
          <p>Entre em contato comigo:</p>
          <ul>
            <li>
              Email:
              <a href="mailto:peda-cos@student.42sp.org.br"
                >peda-cos@student.42sp.org.br</a
              >
            </li>
            <li>
              GitHub:
              <a href="https://github.com/peda-cos" target="_blank"
                >github.com/peda-cos</a
              >
            </li>
            <li>
              LinkedIn:
              <a href="https://linkedin.com/in/peda-cos" target="_blank"
                >linkedin.com/in/peda-cos</a
              >
            </li>
          </ul>
        </div>
      </section>

      <!-- Footer -->
      <footer class="footer">
        <p>Feito com HTML, CSS e JavaScript - Projeto Inception</p>
        <p>&copy; 2024 peda-cos | 42 São Paulo</p>
      </footer>
    </div>

    <script src="script.js"></script>
  </body>
</html>
```

---

## 4. Estilos CSS

### srcs/requirements/bonus/static-site/www/style.css

```css
/* ============================================================================
   STATIC SITE STYLES - peda-cos Portfolio
   ============================================================================ */

/* Reset e variáveis */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

:root {
  --primary: #00d4ff;
  --secondary: #7c3aed;
  --background: #0f0f23;
  --surface: #1a1a2e;
  --text: #e0e0e0;
  --text-muted: #888;
  --success: #4ade80;
  --warning: #fbbf24;
  --error: #f87171;
}

body {
  font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
  background-color: var(--background);
  color: var(--text);
  line-height: 1.6;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

/* Header */
.header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  background: rgba(15, 15, 35, 0.95);
  backdrop-filter: blur(10px);
  z-index: 100;
  padding: 15px 0;
}

.nav {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.logo {
  font-size: 1.5rem;
  font-weight: bold;
  color: var(--primary);
}

.nav-links {
  display: flex;
  list-style: none;
  gap: 30px;
}

.nav-links a {
  color: var(--text);
  text-decoration: none;
  transition: color 0.3s;
}

.nav-links a:hover {
  color: var(--primary);
}

/* Hero Section */
.hero {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-top: 80px;
  gap: 50px;
}

.hero-content {
  flex: 1;
}

.hero h1 {
  font-size: 3rem;
  margin-bottom: 20px;
}

.highlight {
  color: var(--primary);
}

.subtitle {
  font-size: 1.5rem;
  color: var(--secondary);
  margin-bottom: 15px;
}

.description {
  color: var(--text-muted);
  margin-bottom: 30px;
  max-width: 500px;
}

.cta-button {
  display: inline-block;
  padding: 12px 30px;
  background: linear-gradient(135deg, var(--primary), var(--secondary));
  color: white;
  text-decoration: none;
  border-radius: 30px;
  font-weight: bold;
  transition:
    transform 0.3s,
    box-shadow 0.3s;
}

.cta-button:hover {
  transform: translateY(-3px);
  box-shadow: 0 10px 30px rgba(0, 212, 255, 0.3);
}

/* Terminal */
.hero-image {
  flex: 1;
}

.terminal {
  background: var(--surface);
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5);
  max-width: 400px;
}

.terminal-header {
  background: #2d2d44;
  padding: 10px 15px;
  display: flex;
  gap: 8px;
}

.dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
}

.dot.red {
  background: var(--error);
}
.dot.yellow {
  background: var(--warning);
}
.dot.green {
  background: var(--success);
}

.terminal-body {
  padding: 20px;
  font-family: "Courier New", monospace;
  font-size: 0.9rem;
}

.terminal-body p {
  margin-bottom: 5px;
}

.prompt {
  color: var(--success);
}

.output {
  color: var(--text-muted);
  margin-left: 20px;
}

.cursor {
  animation: blink 1s infinite;
}

@keyframes blink {
  0%,
  50% {
    opacity: 1;
  }
  51%,
  100% {
    opacity: 0;
  }
}

/* Sections */
.section {
  padding: 100px 0;
}

.section h2 {
  font-size: 2.5rem;
  text-align: center;
  margin-bottom: 50px;
  color: var(--primary);
}

/* About */
.about-content {
  max-width: 800px;
  margin: 0 auto;
  text-align: center;
}

.about-content p {
  margin-bottom: 20px;
  color: var(--text-muted);
}

/* Skills */
.skills-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 30px;
}

.skill-card {
  background: var(--surface);
  padding: 30px;
  border-radius: 15px;
  text-align: center;
  transition:
    transform 0.3s,
    box-shadow 0.3s;
}

.skill-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 30px rgba(0, 212, 255, 0.2);
}

.skill-icon {
  width: 60px;
  height: 60px;
  background: linear-gradient(135deg, var(--primary), var(--secondary));
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 20px;
  font-weight: bold;
  font-size: 1.5rem;
}

.skill-card h3 {
  margin-bottom: 10px;
}

.skill-card p {
  color: var(--text-muted);
  font-size: 0.9rem;
}

/* Projects */
.projects-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 30px;
}

.project-card {
  background: var(--surface);
  padding: 30px;
  border-radius: 15px;
  border-left: 4px solid var(--primary);
  transition: transform 0.3s;
}

.project-card:hover {
  transform: translateX(10px);
}

.project-card h3 {
  color: var(--primary);
  margin-bottom: 15px;
}

.project-card p {
  color: var(--text-muted);
  margin-bottom: 20px;
}

.tags {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.tags span {
  background: rgba(0, 212, 255, 0.1);
  color: var(--primary);
  padding: 5px 15px;
  border-radius: 20px;
  font-size: 0.8rem;
}

/* Contact */
.contact-info {
  text-align: center;
}

.contact-info ul {
  list-style: none;
  margin-top: 20px;
}

.contact-info li {
  margin-bottom: 15px;
}

.contact-info a {
  color: var(--primary);
  text-decoration: none;
}

.contact-info a:hover {
  text-decoration: underline;
}

/* Footer */
.footer {
  text-align: center;
  padding: 40px 0;
  border-top: 1px solid var(--surface);
  color: var(--text-muted);
}

.footer p {
  margin-bottom: 10px;
}

/* Responsive */
@media (max-width: 768px) {
  .hero {
    flex-direction: column;
    text-align: center;
  }

  .hero h1 {
    font-size: 2rem;
  }

  .nav-links {
    display: none;
  }

  .terminal {
    max-width: 100%;
  }
}
```

### srcs/requirements/bonus/static-site/www/script.js

```javascript
// ============================================================================
// STATIC SITE JAVASCRIPT - peda-cos Portfolio
// ============================================================================

// Smooth scroll para links de navegação
document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
  anchor.addEventListener("click", function (e) {
    e.preventDefault();
    const target = document.querySelector(this.getAttribute("href"));
    if (target) {
      target.scrollIntoView({
        behavior: "smooth",
        block: "start",
      });
    }
  });
});

// Animação de fade-in para seções
const observerOptions = {
  root: null,
  rootMargin: "0px",
  threshold: 0.1,
};

const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.style.opacity = "1";
      entry.target.style.transform = "translateY(0)";
    }
  });
}, observerOptions);

document.querySelectorAll(".section").forEach((section) => {
  section.style.opacity = "0";
  section.style.transform = "translateY(30px)";
  section.style.transition = "opacity 0.6s ease, transform 0.6s ease";
  observer.observe(section);
});

// Console easter egg
console.log(
  "%c42 São Paulo",
  "font-size: 30px; color: #00d4ff; font-weight: bold;",
);
console.log(
  "%cpeda-cos - Inception Project",
  "font-size: 14px; color: #7c3aed;",
);
console.log("Criado com Docker, NGINX e muito café ☕");
```

---

## 5. Docker Compose

### Adicionar ao docker-compose.yml

```yaml
services:
  # ... serviços existentes ...

  # ========================================================================== #
  #                              STATIC SITE                                   #
  # ========================================================================== #

  static-site:
    build:
      context: ./requirements/bonus/static-site
      dockerfile: Dockerfile
    container_name: static-site
    image: static-site
    restart: unless-stopped
    ports:
      - "8081:8081"
    networks:
      - inception
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 5s
```

---

## 6. Testes e Validação

### Iniciar Site Estático

```bash
# Construir e iniciar
docker compose -f srcs/docker-compose.yml build static-site
docker compose -f srcs/docker-compose.yml up -d static-site

# Ver logs
docker compose -f srcs/docker-compose.yml logs static-site
```

### Acessar o Site

Abra no navegador: `http://peda-cos.42.fr:8081`

### Verificar

- [ ] Página carrega corretamente
- [ ] Navegação funciona
- [ ] Animações funcionam
- [ ] Responsivo (testar em diferentes tamanhos)
- [ ] Não usa PHP (requisito do subject)

---

## Próxima Etapa

[Ir para 12-BONUS-PORTAINER.md](./12-BONUS-PORTAINER.md)
