$ErrorActionPreference = "Stop"

Set-Location (Split-Path $PSScriptRoot -Parent)

New-Item -ItemType Directory -Force -Path ".docker" | Out-Null

$envFile = ".docker\\stack.env"

function New-RandomDbUser {
    $userSuffix = -join (((48..57) + (97..122) | Get-Random -Count 8) | ForEach-Object { [char]$_ })
    "getfy_$userSuffix"
}

function New-RandomSecret([int]$len = 32) {
    -join (((48..57) + (65..90) + (97..122) | Get-Random -Count $len) | ForEach-Object { [char]$_ })
}

function Write-EnvFile([string]$path, [hashtable]$vars) {
    $existing = @{}
    if (Test-Path $path) {
        Get-Content $path | ForEach-Object {
            if ($_ -match '^\s*([^#=\s]+)\s*=\s*(.*)\s*$') {
                $existing[$matches[1]] = $matches[2]
            }
        }
    }
    foreach ($k in $vars.Keys) { $existing[$k] = $vars[$k] }
    $content = ($existing.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "`n"
    Set-Content -NoNewline -Path $path -Value $content
}

if (!(Test-Path $envFile)) {
    $dbUser = New-RandomDbUser
    $dbPass = New-RandomSecret 32
    $httpPort = if ($env:GETFY_HTTP_PORT) { $env:GETFY_HTTP_PORT } else { "80" }
    $appUrl = if ($env:GETFY_APP_URL) { $env:GETFY_APP_URL } else { "http://localhost" }
    $webhookPublic = if ($env:GETFY_WEBHOOK_PUBLIC_URL) { $env:GETFY_WEBHOOK_PUBLIC_URL } else { $appUrl }
    Write-EnvFile $envFile @{
        GETFY_DB_CONNECTION = "pgsql"
        GETFY_DB_HOST = "postgres"
        GETFY_DB_PORT = "5432"
        GETFY_DB_DATABASE = "getfy"
        GETFY_DB_USERNAME = $dbUser
        GETFY_DB_PASSWORD = $dbPass
        GETFY_APP_URL = $appUrl
        GETFY_WEBHOOK_PUBLIC_URL = $webhookPublic
        GETFY_HTTP_PORT = $httpPort
        GETFY_QUEUE_CONNECTION = if ($env:GETFY_QUEUE_CONNECTION) { $env:GETFY_QUEUE_CONNECTION } else { "redis" }
        GETFY_CACHE_STORE = if ($env:GETFY_CACHE_STORE) { $env:GETFY_CACHE_STORE } else { "redis" }
        GETFY_SESSION_DRIVER = if ($env:GETFY_SESSION_DRIVER) { $env:GETFY_SESSION_DRIVER } else { "file" }
        GETFY_REDIS_MAXMEMORY = if ($env:GETFY_REDIS_MAXMEMORY) { $env:GETFY_REDIS_MAXMEMORY } else { "128mb" }
        GETFY_REDIS_MAXMEMORY_POLICY = if ($env:GETFY_REDIS_MAXMEMORY_POLICY) { $env:GETFY_REDIS_MAXMEMORY_POLICY } else { "allkeys-lru" }
        GETFY_QUEUE_WORKER_MEMORY = if ($env:GETFY_QUEUE_WORKER_MEMORY) { $env:GETFY_QUEUE_WORKER_MEMORY } else { "128" }
        GETFY_QUEUE_WORKER_MAX_TIME = if ($env:GETFY_QUEUE_WORKER_MAX_TIME) { $env:GETFY_QUEUE_WORKER_MAX_TIME } else { "3600" }
        GETFY_QUEUE_WORKER_MAX_JOBS = if ($env:GETFY_QUEUE_WORKER_MAX_JOBS) { $env:GETFY_QUEUE_WORKER_MAX_JOBS } else { "1000" }
        GETFY_CADDY_HOST = if ($env:GETFY_CADDY_HOST) { $env:GETFY_CADDY_HOST } else { ":80" }
        GETFY_COMPOSE_FILES = if ($env:GETFY_COMPOSE_FILES) { $env:GETFY_COMPOSE_FILES } else { "docker-compose.yml;docker-compose.hostports.yml" }
        GETFY_CADDY_PUBLIC_HOST = if ($env:GETFY_CADDY_PUBLIC_HOST) { $env:GETFY_CADDY_PUBLIC_HOST } else { "" }
        GETFY_LE_EMAIL = if ($env:GETFY_LE_EMAIL) { $env:GETFY_LE_EMAIL } else { "" }
    }
} else {
    $content = Get-Content $envFile -Raw
    $needsRotate = $content -match '^\s*GETFY_DB_USERNAME\s*=\s*(getfy)?\s*$' -or $content -match '^\s*GETFY_DB_PASSWORD\s*=\s*(getfy)?\s*$'
    if ($needsRotate) {
        $dbUser = New-RandomDbUser
        $dbPass = New-RandomSecret 32
        Write-EnvFile $envFile @{
            GETFY_DB_USERNAME = $dbUser
            GETFY_DB_PASSWORD = $dbPass
        }
    }
    $contentMerge = Get-Content $envFile -Raw
    if ($contentMerge -notmatch '(?m)^\s*GETFY_DB_CONNECTION\s*=') { Write-EnvFile $envFile @{ GETFY_DB_CONNECTION = "pgsql" } }
    if ($contentMerge -notmatch '(?m)^\s*GETFY_DB_HOST\s*=') { Write-EnvFile $envFile @{ GETFY_DB_HOST = "postgres" } }
    if ($contentMerge -notmatch '(?m)^\s*GETFY_DB_PORT\s*=') { Write-EnvFile $envFile @{ GETFY_DB_PORT = "5432" } }
    if ($contentMerge -notmatch '(?m)^\s*GETFY_WEBHOOK_PUBLIC_URL\s*=') {
        $appUrlLine = Get-Content $envFile | Where-Object { $_ -match '^\s*GETFY_APP_URL\s*=' } | Select-Object -First 1
        $valApp = "http://localhost"
        if ($appUrlLine -match '^\s*GETFY_APP_URL\s*=\s*(.+)\s*$') { $valApp = $matches[1].Trim() }
        if ($env:GETFY_APP_URL) { $valApp = $env:GETFY_APP_URL }
        $wh = if ($env:GETFY_WEBHOOK_PUBLIC_URL) { $env:GETFY_WEBHOOK_PUBLIC_URL } else { $valApp }
        Write-EnvFile $envFile @{ GETFY_WEBHOOK_PUBLIC_URL = $wh }
    }
    $contentMerge2 = Get-Content $envFile -Raw
    if ($contentMerge2 -notmatch '(?m)^\s*GETFY_COMPOSE_FILES\s*=') {
        Write-EnvFile $envFile @{ GETFY_COMPOSE_FILES = "docker-compose.yml;docker-compose.hostports.yml" }
    }
    elseif ($contentMerge2 -match '(?m)^\s*GETFY_COMPOSE_FILES\s*=\s*docker-compose\.yml\s*$') {
        Write-EnvFile $envFile @{ GETFY_COMPOSE_FILES = "docker-compose.yml;docker-compose.hostports.yml" }
    }
    $contentMerge3 = Get-Content $envFile -Raw
    if ($contentMerge3 -notmatch '(?m)^\s*GETFY_CADDY_PUBLIC_HOST\s*=') {
        Write-EnvFile $envFile @{ GETFY_CADDY_PUBLIC_HOST = "" }
    }
    $contentMerge4 = Get-Content $envFile -Raw
    if ($contentMerge4 -notmatch '(?m)^\s*GETFY_LE_EMAIL\s*=') {
        Write-EnvFile $envFile @{ GETFY_LE_EMAIL = "" }
    }
}

$composeFilesRaw = if ($env:GETFY_COMPOSE_FILES) { $env:GETFY_COMPOSE_FILES } else { "" }
if ([string]::IsNullOrWhiteSpace($composeFilesRaw) -and (Test-Path $envFile)) {
    $line = Get-Content $envFile | Where-Object { $_ -match '^\s*GETFY_COMPOSE_FILES\s*=' } | Select-Object -First 1
    if ($line -match '^\s*GETFY_COMPOSE_FILES\s*=\s*(.+)\s*$') { $composeFilesRaw = $matches[1].Trim() }
}
if ([string]::IsNullOrWhiteSpace($composeFilesRaw)) { $composeFilesRaw = "docker-compose.yml;docker-compose.hostports.yml" }
$composeFiles = $composeFilesRaw -split ';' | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }
$composeArgs = @()
foreach ($f in $composeFiles) {
    $composeArgs += @("-f", $f)
}

# BuildKit no Docker Desktop (Windows) pode falhar ao exportar layers (tls: bad record MAC). Classic builder evita isso.
if ($env:GETFY_USE_BUILDKIT -ne "1") {
    $env:DOCKER_BUILDKIT = "0"
    $env:COMPOSE_DOCKER_CLI_BUILD = "0"
}

docker compose @composeArgs --env-file $envFile up --build -d
