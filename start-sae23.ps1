Write-Host "SAE23 RESTORE FIXED MODE" -ForegroundColor Cyan


# =========================
# 0. START DOCKER DESKTOP
# =========================
Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow

$docker = Get-ChildItem -Path C:\,D:\,E:\ -Recurse -Filter "Docker Desktop.exe" -ErrorAction SilentlyContinue |
Select-Object -First 1

if ($docker) {
    Start-Process $docker.FullName
} else {
    Write-Host "Docker Desktop not found" -ForegroundColor Red
}

Start-Sleep -Seconds 15


# =========================
# 1. PREPARE VOLUMES
# =========================
Write-Host "Preparing volumes..." -ForegroundColor Yellow

New-Item -ItemType Directory -Force -Path ".\volumes\mariadb_Genillon" | Out-Null
New-Item -ItemType Directory -Force -Path ".\volumes\htmlwordpress_Genillon" | Out-Null


# =========================
# 2. EXTRACT BACKUP
# =========================
Write-Host "Extracting backup..." -ForegroundColor Yellow

if (!(Test-Path ".\backup_full.zip")) {
    Write-Host "ERROR: backup_full.zip missing" -ForegroundColor Red
    exit 1
}

Expand-Archive -Path .\backup_full.zip -DestinationPath .\restore_temp -Force


# =========================
# 3. RESTORE WORDPRESS FILES
# =========================
Write-Host "Restoring WordPress files..." -ForegroundColor Yellow

if (Test-Path ".\restore_temp\wordpress_files.zip") {
    Expand-Archive -Path .\restore_temp\wordpress_files.zip -DestinationPath .\volumes\htmlwordpress_Genillon -Force
}


# =========================
# 4. START DOCKER STACK
# =========================
Write-Host "Starting Docker..." -ForegroundColor Yellow

docker compose up -d
Start-Sleep -Seconds 15


# =========================
# 5. WAIT MARIADB READY
# =========================
Write-Host "Waiting MariaDB..." -ForegroundColor Yellow

$maxRetries = 60
$retry = 0

do {
    Start-Sleep -Seconds 2

    docker exec mariadb_Genillon mariadb `
    -u nath `
    -pN@than42421 `
    -e "SELECT 1;" Wordpress > $null 2>&1

    $retry++
    Write-Host "Waiting DB... ($retry/$maxRetries)" -ForegroundColor DarkYellow

} while ($LASTEXITCODE -ne 0 -and $retry -lt $maxRetries)

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR MariaDB not ready" -ForegroundColor Red
    docker logs mariadb_Genillon
    exit 1
}

Write-Host "MariaDB READY" -ForegroundColor Green


# =========================
# 6. RESTORE DATABASE
# =========================
if (Test-Path ".\restore_temp\backup.sql") {

    Write-Host "Restoring DB..." -ForegroundColor Yellow

    Get-Content -Raw .\restore_temp\backup.sql -Encoding UTF8 |
    docker exec -i mariadb_Genillon mariadb -u nath -pN@than42421 Wordpress
}


# =========================
# 7. CLEAN TEMP
# =========================
Remove-Item -Recurse -Force .\restore_temp -ErrorAction SilentlyContinue


# =========================
# 8. OPEN SERVICES
# =========================
Start-Process "http://127.0.0.1"
Start-Process "http://127.0.0.1:9000"
Start-Process "http://127.0.0.1:82"

Write-Host "RESTORE COMPLETE OK" -ForegroundColor Green


# =========================
# 9. WORDPRESS AUTO UPDATE
# =========================
Write-Host "Updating WordPress (core + plugins + themes)..." -ForegroundColor Yellow

# Update core WordPress
docker exec -i mariadb_Genillon bash -c "wp core update --allow-root --path=/var/www/html"

# Update database if needed
docker exec -i mariadb_Genillon bash -c "wp core update-db --allow-root --path=/var/www/html"

# Update all plugins
docker exec -i mariadb_Genillon bash -c "wp plugin update --all --allow-root --path=/var/www/html"

# Update all themes
docker exec -i mariadb_Genillon bash -c "wp theme update --all --allow-root --path=/var/www/html"

Write-Host "WordPress updated successfully" -ForegroundColor Green