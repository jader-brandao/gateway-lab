$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

# Só Postgres + Redis no Docker — Laravel, fila e scheduler rodam no host (ex.: Laragon).
docker compose -p gateway-lab-db -f docker-compose.local-db.yml up -d

$pgPort = if ($env:LOCALDB_PG_PORT) { $env:LOCALDB_PG_PORT } else { "5433" }
$redisPort = if ($env:LOCALDB_REDIS_PORT) { $env:LOCALDB_REDIS_PORT } else { "6379" }
Write-Host "Postgres (host): $pgPort | Redis (host): $redisPort — .env: DB_HOST=127.0.0.1 REDIS_HOST=127.0.0.1"
