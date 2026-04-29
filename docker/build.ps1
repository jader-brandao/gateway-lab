$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

# BuildKit no Docker Desktop (Windows) às vezes falha com: failed to copy: tls: bad record MAC
if ($env:GETFY_USE_BUILDKIT -ne "1") {
    $env:DOCKER_BUILDKIT = "0"
    $env:COMPOSE_DOCKER_CLI_BUILD = "0"
}

$composeFilesRaw = if ($env:GETFY_COMPOSE_FILES) { $env:GETFY_COMPOSE_FILES } else { "docker-compose.yml" }
$composeFiles = $composeFilesRaw -split ';' | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }
$composeArgs = @()
foreach ($f in $composeFiles) {
    $composeArgs += @("-f", $f)
}

docker compose @composeArgs build @args
