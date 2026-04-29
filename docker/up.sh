#!/bin/sh
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p .docker

ENV_FILE=".docker/stack.env"
if [ ! -f "$ENV_FILE" ]; then
  HTTP_PORT="${GETFY_HTTP_PORT:-80}"
  APP_URL="${GETFY_APP_URL:-http://localhost}"
  WEBHOOK_PUBLIC="${GETFY_WEBHOOK_PUBLIC_URL:-$APP_URL}"

  U="getfy_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 8)"
  P="$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)"

  COMPOSE_FILES_NEW="${GETFY_COMPOSE_FILES:-docker-compose.yml;docker-compose.prod.yml}"

  cat > "$ENV_FILE" <<EOF
GETFY_DB_CONNECTION=pgsql
GETFY_DB_HOST=postgres
GETFY_DB_PORT=5432
GETFY_DB_DATABASE=getfy
GETFY_DB_USERNAME=$U
GETFY_DB_PASSWORD=$P
GETFY_APP_URL=$APP_URL
GETFY_WEBHOOK_PUBLIC_URL=$WEBHOOK_PUBLIC
GETFY_HTTP_PORT=$HTTP_PORT
GETFY_COMPOSE_FILES=$COMPOSE_FILES_NEW
GETFY_CADDY_PUBLIC_HOST=${GETFY_CADDY_PUBLIC_HOST:-}
GETFY_LE_EMAIL=${GETFY_LE_EMAIL:-}
GETFY_QUEUE_CONNECTION=${GETFY_QUEUE_CONNECTION:-redis}
GETFY_CACHE_STORE=${GETFY_CACHE_STORE:-redis}
GETFY_SESSION_DRIVER=${GETFY_SESSION_DRIVER:-file}
GETFY_REDIS_MAXMEMORY=${GETFY_REDIS_MAXMEMORY:-128mb}
GETFY_REDIS_MAXMEMORY_POLICY=${GETFY_REDIS_MAXMEMORY_POLICY:-allkeys-lru}
GETFY_QUEUE_WORKER_MEMORY=${GETFY_QUEUE_WORKER_MEMORY:-128}
GETFY_QUEUE_WORKER_MAX_TIME=${GETFY_QUEUE_WORKER_MAX_TIME:-3600}
GETFY_QUEUE_WORKER_MAX_JOBS=${GETFY_QUEUE_WORKER_MAX_JOBS:-1000}
GETFY_CADDY_HOST=${GETFY_CADDY_HOST:-:80}
EOF
else
  if grep -Eq '^\s*GETFY_DB_USERNAME\s*=\s*$' "$ENV_FILE" || grep -Eq '^\s*GETFY_DB_PASSWORD\s*=\s*$' "$ENV_FILE" \
    || grep -Eq '^\s*GETFY_DB_USERNAME\s*=\s*getfy\s*$' "$ENV_FILE" || grep -Eq '^\s*GETFY_DB_PASSWORD\s*=\s*getfy\s*$' "$ENV_FILE"; then
    U="getfy_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 8)"
    P="$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)"
    TMP="$(mktemp)"
    awk -v U="$U" -v P="$P" '
      BEGIN { u=0; p=0 }
      $0 ~ /^GETFY_DB_USERNAME=/ { print "GETFY_DB_USERNAME=" U; u=1; next }
      $0 ~ /^GETFY_DB_PASSWORD=/ { print "GETFY_DB_PASSWORD=" P; p=1; next }
      { print }
      END {
        if (!u) print "GETFY_DB_USERNAME=" U
        if (!p) print "GETFY_DB_PASSWORD=" P
      }
    ' "$ENV_FILE" > "$TMP"
    mv "$TMP" "$ENV_FILE"
  fi
fi

if [ -f "$ENV_FILE" ] && ! grep -Eq '^\s*GETFY_WEBHOOK_PUBLIC_URL\s*=' "$ENV_FILE"; then
  LINE_APP="$(grep -E '^GETFY_APP_URL=' "$ENV_FILE" 2>/dev/null | head -1 || true)"
  VAL_APP="${LINE_APP#GETFY_APP_URL=}"
  VAL_APP="${GETFY_APP_URL:-${VAL_APP:-http://localhost}}"
  echo "GETFY_WEBHOOK_PUBLIC_URL=${GETFY_WEBHOOK_PUBLIC_URL:-$VAL_APP}" >> "$ENV_FILE"
fi

# Normaliza banco para PostgreSQL em atualizações de ambientes legados.
TMP_DB="$(mktemp)"
awk '
  BEGIN { c=0; h=0; p=0 }
  $0 ~ /^GETFY_DB_CONNECTION=/ { print "GETFY_DB_CONNECTION=pgsql"; c=1; next }
  $0 ~ /^GETFY_DB_HOST=/ { print "GETFY_DB_HOST=postgres"; h=1; next }
  $0 ~ /^GETFY_DB_PORT=/ { print "GETFY_DB_PORT=5432"; p=1; next }
  { print }
  END {
    if (!c) print "GETFY_DB_CONNECTION=pgsql"
    if (!h) print "GETFY_DB_HOST=postgres"
    if (!p) print "GETFY_DB_PORT=5432"
  }
' "$ENV_FILE" > "$TMP_DB"
mv "$TMP_DB" "$ENV_FILE"

# VPS/Linux: inclui Caddy + compose de produção por omissão; defina GETFY_COMPOSE_FILES=docker-compose.yml para só app.
if [ -f "$ENV_FILE" ]; then
  if ! grep -Eq '^\s*GETFY_COMPOSE_FILES\s*=' "$ENV_FILE"; then
    echo "GETFY_COMPOSE_FILES=docker-compose.yml;docker-compose.prod.yml" >> "$ENV_FILE"
  fi
  if ! grep -Eq '^\s*GETFY_CADDY_PUBLIC_HOST\s*=' "$ENV_FILE"; then
    echo "GETFY_CADDY_PUBLIC_HOST=" >> "$ENV_FILE"
  fi
  if ! grep -Eq '^\s*GETFY_LE_EMAIL\s*=' "$ENV_FILE"; then
    echo "GETFY_LE_EMAIL=" >> "$ENV_FILE"
  fi
  if grep -Eq '^[[:space:]]*GETFY_COMPOSE_FILES[[:space:]]*=[[:space:]]*docker-compose\.yml[[:space:]]*$' "$ENV_FILE"; then
    TMP_CF="$(mktemp)"
    awk '
      $0 ~ /^[[:space:]]*GETFY_COMPOSE_FILES[[:space:]]*=[[:space:]]*docker-compose\.yml[[:space:]]*$/ {
        print "GETFY_COMPOSE_FILES=docker-compose.yml;docker-compose.hostports.yml"
        next
      }
      { print }
    ' "$ENV_FILE" > "$TMP_CF"
    mv "$TMP_CF" "$ENV_FILE"
  fi
fi

# Corrige stack.env: esquema mal digitado (gttps), porta HTTP vazia (quebra publish do Caddy).
if [ -f "$ENV_FILE" ]; then
  TMPFX="$(mktemp)"
  sed \
    -e 's/^\(GETFY_APP_URL=\)gttps:/\1https:/' \
    -e 's/^\(GETFY_APP_URL=\)GTTPS:/\1https:/' \
    -e 's/^\(GETFY_APP_URL=\)htps:/\1https:/' \
    -e 's/^\(GETFY_APP_URL=\)HTPS:/\1https:/' \
    -e 's/^\(GETFY_APP_URL=\)htp:/\1http:/' \
    -e 's/^\(GETFY_APP_URL=\)HTP:/\1http:/' \
    -e 's/^\(GETFY_WEBHOOK_PUBLIC_URL=\)gttps:/\1https:/' \
    -e 's/^\(GETFY_WEBHOOK_PUBLIC_URL=\)GTTPS:/\1https:/' \
    -e 's/^\(GETFY_WEBHOOK_PUBLIC_URL=\)htps:/\1https:/' \
    -e 's/^\(GETFY_WEBHOOK_PUBLIC_URL=\)HTPS:/\1https:/' \
    -e 's/^\(GETFY_WEBHOOK_PUBLIC_URL=\)htp:/\1http:/' \
    -e 's/^\(GETFY_WEBHOOK_PUBLIC_URL=\)HTP:/\1http:/' \
    -e 's/^GETFY_HTTP_PORT=$/GETFY_HTTP_PORT=80/' \
    -e 's/^GETFY_HTTP_PORT=[[:space:]]*$/GETFY_HTTP_PORT=80/' \
    "$ENV_FILE" > "$TMPFX" && mv "$TMPFX" "$ENV_FILE"
fi

if [ -n "${GETFY_COMPOSE_FILES:-}" ]; then
  COMPOSE_FILES="$GETFY_COMPOSE_FILES"
elif [ -f "$ENV_FILE" ]; then
  COMPOSE_FILES="$(grep -E '^GETFY_COMPOSE_FILES=' "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- || true)"
  COMPOSE_FILES="${COMPOSE_FILES:-docker-compose.yml;docker-compose.prod.yml}"
else
  COMPOSE_FILES="docker-compose.yml;docker-compose.prod.yml"
fi
COMPOSE_ARGS=""
OLD_IFS="$IFS"
IFS=';'
for f in $COMPOSE_FILES; do
  if [ -n "$f" ]; then
    COMPOSE_ARGS="$COMPOSE_ARGS -f $f"
  fi
done
IFS="$OLD_IFS"

docker compose $COMPOSE_ARGS --env-file "$ENV_FILE" up --build -d --remove-orphans

# Recria o Caddy para aplicar portas 80/443 (evita container antigo sem publish após mudanças no compose).
case "$COMPOSE_FILES" in
  *docker-compose.prod.yml*)
    docker compose $COMPOSE_ARGS --env-file "$ENV_FILE" up -d --force-recreate caddy
    ;;
esac
