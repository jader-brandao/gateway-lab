$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

docker compose -p gateway-lab-db -f docker-compose.local-db.yml down
