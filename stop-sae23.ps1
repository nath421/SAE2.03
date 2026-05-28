Write-Host "SAE23 STOP + BACKUP + CLEAN + GIT (FIXED)" -ForegroundColor Cyan


# =========================
# 1. CHECK MARIADB
# =========================
Write-Host "Checking MariaDB..." -ForegroundColor Yellow

docker exec mariadb_Genillon mariadb-admin ping -u root -pN@than42421 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "MariaDB NOT responding -> STOP" -ForegroundColor Red
    exit 1
}

Write-Host "MariaDB OK" -ForegroundColor Green


# =========================
# 2. SAFE DATABASE DUMP (FIX IMPORTANT)
# =========================
Write-Host "Dumping database..." -ForegroundColor Yellow

docker exec mariadb_Genillon sh -c "mariadb-dump -u root -pN@than42421 Wordpress --single-transaction --quick --lock-tables=false" > backup.sql

if (!(Test-Path ".\backup.sql") -or (Get-Item ".\backup.sql").Length -lt 1000) {
    Write-Host "ERROR: backup.sql invalid or empty" -ForegroundColor Red
    exit 1
}

Write-Host "Database backup OK" -ForegroundColor Green


# =========================
# 3. WORDPRESS FILES BACKUP (SAFE)
# =========================
Write-Host "Backing up WordPress files..." -ForegroundColor Yellow

if (!(Test-Path ".\volumes\htmlwordpress_Genillon")) {
    Write-Host "ERROR: WordPress volume missing" -ForegroundColor Red
    exit 1
}

Compress-Archive -Path .\volumes\htmlwordpress_Genillon\* -DestinationPath wordpress_files.zip -Force

Write-Host "WordPress files backup OK" -ForegroundColor Green


# =========================
# 4. STOP DOCKER
# =========================
Write-Host "Stopping Docker..." -ForegroundColor Yellow
docker compose down


# =========================
# 5. CLEAN VOLUMES (SAFE MODE)
# =========================
Write-Host "Cleaning volumes..." -ForegroundColor Yellow

if (Test-Path ".\volumes") {
    Remove-Item -Recurse -Force .\volumes
}

Write-Host "Volumes cleaned" -ForegroundColor Green


# =========================
# 6. CREATE FINAL BACKUP ZIP
# =========================
Write-Host "Creating final backup..." -ForegroundColor Yellow

if (Test-Path ".\backup_full.zip") {
    Remove-Item .\backup_full.zip -Force
}

Compress-Archive -Path backup.sql, wordpress_files.zip -DestinationPath backup_full.zip -Force

Write-Host "backup_full.zip CREATED" -ForegroundColor Green


# =========================
# 7. CLEAN TEMP FILES
# =========================
Remove-Item backup.sql -Force -ErrorAction SilentlyContinue
Remove-Item wordpress_files.zip -Force -ErrorAction SilentlyContinue


# =========================
# 8. GIT SAFE SYNC (FIX IMPORTANT)
# =========================
Write-Host "Sync GitHub..." -ForegroundColor Yellow

git add .

git commit -m "SAE23 backup auto" 2>$null

git pull origin main --rebase

if ($LASTEXITCODE -ne 0) {
    Write-Host "Git pull failed -> abort push" -ForegroundColor Red
    exit 1
}

git push

Write-Host "GIT SYNC DONE" -ForegroundColor Green


# =========================
# FINAL
# =========================
Write-Host "FULL BACKUP COMPLETE SUCCESS" -ForegroundColor Green