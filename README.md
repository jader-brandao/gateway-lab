# Getfy (Open Source)

Plataforma Laravel + Vue para checkout, área de membros e estrutura completa de pagamentos.

## Instalação rápida

- Hospedagem compartilhada (upload manual): acesse `https://SEU_DOMINIO/install`
- VPS (terminal): `bash -c "$(curl -fsSL https://raw.githubusercontent.com/gatewaylab-hub/gateway/main/install.sh)"`
- Docker na Hostinger (deploy por URL do GitHub): use `docker-compose.yml` e `docker-compose.hostports.yml` (duas stacks no painel ou comando com `-f` duas vezes)

---

## Requisitos

### Hospedagem compartilhada

- PHP 8.2+
- MySQL/MariaDB (recomendado MySQL 8+)
- Extensões PHP comuns do Laravel: `pdo_mysql`, `mbstring`, `openssl`, `ctype`, `json`, `tokenizer`, `xml`, `bcmath`, `intl`, `zip`
- Permissão de escrita nas pastas: `storage/` e `bootstrap/cache/`
- `.htaccess` habilitado (Apache/LiteSpeed) ou regras equivalentes (Nginx)

Observação: o instalador tenta rodar Composer e build do front automaticamente. Em hospedagens onde isso é bloqueado, ele segue usando `vendor/` e `public/build` existentes, se estiverem presentes no upload.

### VPS (instalação automática)

- Ubuntu/Debian (precisa de `apt-get`)
- Acesso SSH com usuário `root` ou com `sudo`

---

## Instalação em hospedagem compartilhada (upload manual + /install)

Este modo é o mais indicado quando você não tem acesso a SSH/terminal.

### 1) Criar o banco de dados

1. No painel da sua hospedagem, crie um banco MySQL e um usuário.
2. Anote: Host, Porta (geralmente 3306), Nome do banco, Usuário e Senha.

### 2) Baixar e enviar os arquivos

1. No GitHub, clique em **Code → Download ZIP**.
2. Extraia o ZIP no seu computador.
3. Envie todos os arquivos para o servidor (normalmente `public_html/`).

Dica para leigos: se o painel permitir “Extrair ZIP” no servidor, envie o `.zip` e use a opção de extrair para evitar upload demorado.

### 3) Dar permissões de escrita

Garanta que estas pastas sejam graváveis pelo PHP:

- `storage/`
- `bootstrap/cache/`

Se sua hospedagem tiver “Permissões” no gerenciador de arquivos, use 775 (ou 777 se não houver alternativa, apenas durante a instalação).

### 4) Rodar o instalador pelo navegador

1. Abra: `https://SEU_DOMINIO/install`
2. Preencha a URL do sistema (ex.: `https://seudominio.com`), os dados do banco (host/porta/banco/usuário/senha) e o “Session driver” (em hospedagem compartilhada, use `file` na maioria dos casos).
3. Finalize as 4 etapas.

Ao terminar, o instalador marca `APP_INSTALLED=true` no `.env` e desativa o instalador automaticamente (a pasta `public/install` é renomeada para `public/.install`).

### 5) Criar o primeiro administrador

Depois de instalar, acesse:

- `https://SEU_DOMINIO/criar-admin`

Se já existir um usuário administrador, essa tela redireciona para o login.

### 6) Configurar o cron (importante em hospedagem compartilhada)

Para rotinas automáticas (fila/agendamentos), configure uma chamada a cada minuto:

- URL: `https://SEU_DOMINIO/cron?token=SEU_CRON_SECRET`

Onde encontrar o token:

1. Abra o arquivo `.env` no servidor.
2. Procure por `CRON_SECRET=...` (ele é gerado no final da instalação).

Como configurar:

1. Se sua hospedagem tiver Cron Jobs, crie um cron a cada minuto chamando a URL acima (via `curl`/`wget`).
2. Se não tiver cron, use um serviço externo (ex.: cron-job.org / EasyCron) para bater nessa URL a cada minuto.

---

## Instalação em VPS (recomendado) — instalador automático via SSH

Este modo instala e sobe tudo via Docker (app **Nginx + PHP-FPM** + banco + redis + scheduler). No VPS, o instalador usa também **`docker-compose.prod.yml`**: **Caddy** na borda do host nas portas **80** e **443**, com **HTTPS automático (Let’s Encrypt / ACME)** quando a URL pública for um **domínio** com DNS apontando para o servidor.

O banco padrão do stack Docker é **PostgreSQL**.

### 1) Rodar o instalador

Conecte via SSH e execute:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gatewaylab-hub/gateway/main/install.sh)"
```

O que esse comando faz:

1. Instala dependências básicas e Docker (se não existir).
2. Clona o repositório em `/opt/getfy` (padrão).
3. Sobe os containers com `docker compose` (inclui Caddy em produção no Linux).

### 2) Abrir a configuração do Docker no navegador

Ao final, o terminal indica URLs parecidas com:

- `http://SEU_IP:80/docker-setup` (sempre útil na primeira vez)
- `https://seudominio.com/docker-setup` (quando você já informou um domínio com DNS apontando para o VPS)

Abra e informe o domínio público (ex.: `seudominio.com`). Isso ajusta `APP_URL` e finaliza a configuração inicial.

#### HTTPS, DNS e Cloudflare

- **Let’s Encrypt** na origem exige que o **nome do host** resolva para este servidor e que as portas **80** e **443** cheguem ao container **Caddy** (firewall / painel do provedor).
- **Sem domínio (só IP)**: o acesso continua em **HTTP**; não há certificado público válido para o IP.
- **Cloudflare**: em **Full** ou **Full (strict)** o tráfego entre Cloudflare e a origem é HTTPS. Com **strict**, a origem precisa de certificado **público confiável** — o Caddy obtém um da Let’s Encrypt automaticamente (desde que o ACME funcione).
- Opcional: defina `GETFY_LE_EMAIL` em `.docker/stack.env` com um e-mail de contato para a conta ACME (recomendado em produção).

### 3) Criar o primeiro administrador

- `https://SEU_DOMINIO/criar-admin` (ou `http://SEU_IP/criar-admin` se ainda estiver só em HTTP)

### (Opcional) Trocar porta/dir de instalação

Você pode definir variáveis antes de rodar o instalador:

```bash
GETFY_HTTP_PORT=8080 GETFY_DIR=/opt/getfy bash -c "$(curl -fsSL https://raw.githubusercontent.com/gatewaylab-hub/gateway/main/install.sh)"
```

---

## Docker na Hostinger (deploy por URL do GitHub)

Este modo é para quando você usa um painel que permite “Criar aplicação a partir de um repositório Git”.

### 1) Criar a aplicação

1. No painel da Hostinger, escolha criar uma nova aplicação a partir de um repositório (Git/URL).
2. Cole a URL do repositório do GitHub.
3. Se o painel permitir vários ficheiros Compose, use **`docker-compose.yml`** e **`docker-compose.hostports.yml`** (o primeiro não expõe a porta 80 sozinho; o segundo publica `GETFY_HTTP_PORT`→80 no `app`). Para HTTPS automático na origem como no instalador VPS, use **`docker-compose.yml`** + **`docker-compose.prod.yml`** (Caddy). Muitos painéis só aceitam um ficheiro — nesse caso use o **modo VPS (SSH)** ou um proxy TLS à frente do painel.

### 2) Portas e persistência

1. Garanta que a aplicação exponha a porta 80 (ou a porta exigida pelo painel).
2. Garanta persistência para `storage/` (uploads, logs, cache) e `.docker/` (estado do setup).

Se o painel não oferecer volumes persistentes, os dados podem ser perdidos em um redeploy.

### 3) Finalizar no navegador

Depois do deploy, acesse:

- `https://SEU_DOMINIO/docker-setup`

E em seguida:

- `https://SEU_DOMINIO/criar-admin`

Se o seu painel não suportar `docker-compose.yml`, a alternativa mais simples é usar o modo VPS (SSH) acima.

---

## Para atualizar:
VPS:
1. Conecte via SSH.
2. Execute: `bash -c "$(curl -fsSL https://raw.githubusercontent.com/gatewaylab-hub/gateway/main/update.sh)"`.

Hospedagem compartilhada:
1. Baixe o zip update vX.X.X do repositório.
2. Extraia o conteúdo na pasta do projeto.
3. Vá em configurações > Update > Rodar migration

## Solução de problemas (rápido)

- **Cloudflare 502 (Bad gateway)** com o domínio proxied (nuvem laranja): muitas vezes o modo SSL **Flexible** (Cloudflare→origem só em HTTP:80) conflita com HTTPS na origem. Passe a **Full** ou **Full (strict)** no painel SSL/TLS da Cloudflare. **Não use `https://` com o IP público** do servidor — só há TLS para o **domínio**; por IP use `http://SEU_IP`.
- **Cloudflare 521 (Web server is down)** com o proxy ligado: confirme no servidor com `docker ps` que o container **caddy** mostra `0.0.0.0:80->80` e `443->443`. Se a coluna PORTS estiver vazia no Caddy, rode `cd /opt/getfy && sh docker/up.sh` (ou `docker compose ... up -d --force-recreate caddy`) após atualizar o repositório. Confirme também **firewall** (`ufw allow 80,443/tcp`) e que não digitou **`gttps`** em vez de **`https`** na URL pública.
- **Container `app` em `Restarting` / `unhealthy`**: veja `docker logs getfy-app-1`. Se o Nginx não arranca por `socket() [::]:80` (IPv6), a stack já usa só `listen 80` no `docker/nginx/default.conf` — faça `git pull` e `docker compose ... up --build -d`. O healthcheck só confirma que a porta 80 responde no container (não usa `/up` do Laravel).
- **`Bind for 0.0.0.0:80 failed: port is already allocated`** ao subir o Caddy: atualize o repositório (`git pull` / `update.sh`) e volte a subir a stack. O `docker-compose.yml` base já não publica a porta 80 no `app` (evita conflito com o Caddy). Se a porta 80 no **host** estiver ocupada por Apache/Nginx fora do Docker, pare esse serviço ou defina `GETFY_HTTP_PORT` para outra porta no `.docker/stack.env` e mapeie o tráfego externo.
- Erro 500 logo ao abrir o site: verifique PHP 8.2+, permissões de `storage/` e `bootstrap/cache/` e se o `.env` existe.
- Instalador não conclui “Composer”: algumas hospedagens bloqueiam `proc_open`. Nesses casos, suba o projeto já com `vendor/` (rode `composer install` no seu PC antes de enviar) e tente novamente.
- Arquivos em `public/storage` não aparecem: `storage:link` pode falhar em hospedagens sem symlink. Se acontecer, crie manualmente um link/symlink de `public/storage` → `storage/app/public` (ou use um painel que suporte isso).
- Rotinas automáticas não rodam: configure o cron pela URL `/cron?token=...` a cada minuto.

Se você deseja apoiar o desenvolvimento diretamente:
| Pix | Chave |
|---|---|
| Aleatória | `ce05f7d1-27db-4d46-bca5-0a80c621349a` |

