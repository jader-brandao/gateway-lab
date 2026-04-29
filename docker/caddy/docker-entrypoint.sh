#!/bin/sh
set -e

APP_URL="${GETFY_APP_URL:-http://localhost}"
HOST="${GETFY_CADDY_PUBLIC_HOST:-}"

if [ -z "$HOST" ]; then
  host_raw="${APP_URL#*://}"
  HOST="${host_raw%%[/:]*}"
  case "$HOST" in
    \[*\]*)
      HOST=""
      ;;
  esac
fi

HOST=$(printf '%s' "$HOST" | tr '[:upper:]' '[:lower:]' | tr -d '\r\n')

case "$HOST" in
  \[*\]*)
    ;;
  *:*)
    HOST="${HOST%%:*}"
    ;;
esac

USE_TLS=0
case "$HOST" in
  ""|localhost|127.0.0.1|::1)
    USE_TLS=0
    ;;
  *)
    if printf '%s' "$HOST" | grep -qE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$'; then
      USE_TLS=0
    elif printf '%s' "$HOST" | grep -q '\.'; then
      USE_TLS=1
    fi
    ;;
esac

: > /etc/caddy/Caddyfile

if [ "$USE_TLS" -eq 1 ]; then
  # Evita redireciono automático HTTP→HTTPS na origem: com Cloudflare "Flexible" a CF fala só HTTP:80
  # e um 301 para https na origem costuma resultar em 502. Use SSL/TLS "Full" ou "Full (strict)" na CF.
  printf '%s\n' '{' >> /etc/caddy/Caddyfile
  if [ -n "${GETFY_LE_EMAIL:-}" ]; then
    printf '  email %s\n' "${GETFY_LE_EMAIL}" >> /etc/caddy/Caddyfile
  fi
  printf '%s\n' '  auto_https disable_redirects' '}' '' >> /etc/caddy/Caddyfile
  printf '%s {\n  reverse_proxy app:80 {\n    transport http {\n      versions 1.1\n    }\n  }\n}\n' "$HOST" >> /etc/caddy/Caddyfile
else
  printf '%s\n' ':80 {' '  reverse_proxy app:80 {' '    transport http {' '      versions 1.1' '    }' '  }' '}' >> /etc/caddy/Caddyfile
fi

exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
