# Backup-Drivers.ps1
# One-click backup of all third-party Windows drivers.

# ---------- Settings ----------
$BackupRoot = "D:\DriverBackup"   # Where backups are stored
$KeepLast   = 5                   # Keep this many dated backups (0 = never delete)
# ------------------------------

# Self-elevate to Administrator if needed
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList `
        "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$ErrorActionPreference = "Stop"

try {
    # Make sure the target drive exists
    $drive = Split-Path $BackupRoot -Qualifier
    if (-not (Test-Path $drive)) { throw "Drive $drive was not found." }

    # Create a dated folder, e.g. D:\DriverBackup\2026-10-10_1530
    $dest = Join-Path $BackupRoot (Get-Date -Format "yyyy-MM-dd_HHmm")
    New-Item -ItemType Directory -Path $dest -Force | Out-Null

    Write-Host "Exporting drivers to $dest ..." -ForegroundColor Cyan
    Export-WindowsDriver -Online -Destination $dest | Out-Null

    # Verify and save a readable list of what was exported
    $installed = @(Get-WindowsDriver -Online)
    $folders   = @(Get-ChildItem $dest -Directory)
    $installed |
        Select-Object ClassName, ProviderName, Version, Date, Driver, OriginalFileName |
        Sort-Object ClassName, ProviderName |
        Export-Csv (Join-Path $dest "driver-list.csv") -NoTypeInformation -Encoding UTF8

    $sizeMB = [math]::Round(
        (Get-ChildItem $dest -Recurse -File | Measure-Object Length -Sum).Sum / 1MB, 1)

    Write-Host "Done: $($folders.Count) driver folders exported ($sizeMB MB)." -ForegroundColor Green
    Write-Host "Third-party drivers installed: $($installed.Count)"

    # Prune old backups
    if ($KeepLast -gt 0) {
        Get-ChildItem $BackupRoot -Directory |
            Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}_\d{4}$' } |
            Sort-Object Name -Descending |
            Select-Object -Skip $KeepLast |
            ForEach-Object {
                Write-Host "Removing old backup: $($_.Name)" -ForegroundColor Yellow
                Remove-Item $_.FullName -Recurse -Force
            }
    }
}
catch {
    Write-Host "Backup failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to close"
