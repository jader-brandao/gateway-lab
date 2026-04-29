#!/usr/bin/env sh
# Carregue com: . docker/prompt-public-url.sh (a partir da raiz do repositório)
# Define GETFY_WEBHOOK_PUBLIC_URL e GETFY_APP_URL (se ainda vazio) para o Docker/stack.env.
# Sobrescreva exportando GETFY_WEBHOOK_PUBLIC_URL antes do source para pular o prompt.

GETFY_DEFAULT_PUBLIC_URL="${GETFY_DEFAULT_PUBLIC_URL:-http://getfy-gateway.test}"

# Corrige erros comuns de digitação no esquema (ex.: gttps → https).
getfy_normalize_public_url() {
  printf '%s' "$1" | tr -d '\r' | sed \
    -e 's/^gttps:\/\//https:\/\//' \
    -e 's/^GTTPS:\/\//https:\/\//' \
    -e 's/^htps:\/\//https:\/\//' \
    -e 's/^HTPS:\/\//https:\/\//' \
    -e 's/^htp:\/\//http:\/\//' \
    -e 's/^HTP:\/\//http:\/\//'
}

if [ -z "${GETFY_WEBHOOK_PUBLIC_URL:-}" ]; then
  if [ -t 0 ] 2>/dev/null; then
    echo ""
    echo "URL pública do gateway (APP_URL e GETFY_WEBHOOK_PUBLIC_URL — postbacks dos adquirentes)."
    echo "Em VPS com Docker: use https://seu-dominio.com quando o DNS já apontar para o servidor (Caddy obtém SSL na origem; Cloudflare Full/Strict ok)."
    echo "Sem domínio ainda: use http://IP_OU_HOST:porta — HTTPS automático (Let's Encrypt) exige hostname com DNS público."
    printf 'Digite a URL [%s]: ' "$GETFY_DEFAULT_PUBLIC_URL"
    read -r GETFY_PUBLIC_URL_READ || GETFY_PUBLIC_URL_READ=""
    GETFY_WEBHOOK_PUBLIC_URL="${GETFY_PUBLIC_URL_READ:-$GETFY_DEFAULT_PUBLIC_URL}"
  else
    GETFY_WEBHOOK_PUBLIC_URL="$GETFY_DEFAULT_PUBLIC_URL"
  fi
  export GETFY_WEBHOOK_PUBLIC_URL
fi

GETFY_WEBHOOK_PUBLIC_URL="$(getfy_normalize_public_url "${GETFY_WEBHOOK_PUBLIC_URL:-}")"
export GETFY_WEBHOOK_PUBLIC_URL

if [ -z "${GETFY_APP_URL:-}" ]; then
  export GETFY_APP_URL="$GETFY_WEBHOOK_PUBLIC_URL"
else
  export GETFY_APP_URL
fi

GETFY_APP_URL="$(getfy_normalize_public_url "${GETFY_APP_URL:-}")"
export GETFY_APP_URL
