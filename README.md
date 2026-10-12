# POWERSHELL-ONE-CLICK-BACKUP-DRIVERS-TO-YOUR-DRIVE
powershell scripts .ps1 that helps you to back backup all of your drivers to your destined drive.


# Backing up Windows drivers from the terminal

Windows has a built-in way to export every third-party driver in one command. Run **PowerShell as Administrator** (right-click Windows Terminal → Run as administrator, or Ctrl+Shift+Enter from the Start menu search).

## Option 1: Export-WindowsDriver (recommended)

```powershell
New-Item -ItemType Directory -Path "D:\DriverBackup" -Force
Export-WindowsDriver -Online -Destination "D:\DriverBackup"
```

This copies every **third-party** driver from the driver store (the ones you or Windows Update installed, such as GPU, chipset, network, audio, and so on) into the folder. Each driver gets its own subfolder with the `.inf`, `.sys`, and `.cat` files. Built-in Microsoft drivers aren't included, which is what you want, since Windows already ships those.

Replace `D:\DriverBackup` with a drive other than `C:`, or a USB stick, so the backup survives if the system drive dies.

## Option 2: pnputil (the older classic)

```powershell
pnputil /export-driver * "D:\DriverBackup"
```

It does essentially the same thing. It's handy if you're in a plain Command Prompt or a recovery environment.

## Check what you got

```powershell
Get-ChildItem "D:\DriverBackup" -Directory | Measure-Object
Get-WindowsDriver -Online | Select-Object Driver, OriginalFileName, ProviderName, ClassName, Version | Sort-Object ClassName
```

The second command lists the third-party drivers currently installed, so you can compare it with the folders you exported.

## Restoring later

After a fresh Windows install, run this as Administrator:

```powershell
pnputil /add-driver "D:\DriverBackup\*.inf" /subdirs /install
```

Or install a single device's driver via Device Manager → Update driver → Browse my computer → point it at the backup folder.

## Caveats

- **Only INF-based drivers are captured.** Drivers installed by a setup program that does extra work (some GPU control panels, audio suites such as Realtek's companion apps, RGB or peripheral software) may need their original installers too. For a gaming laptop or ROG machine, I'd also download the official installer packages for the GPU, chipset, and Wi-Fi from the manufacturer.
- **Don't restore blindly onto a different PC model.** The backup is best for the same hardware.
- **Keep a copy of the folder off the machine** (USB drive or cloud storage).

## Bonus: automate it into dated folders

```powershell
$dest = "D:\DriverBackup\$(Get-Date -Format 'yyyy-MM-dd')"
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Export-WindowsDriver -Online -Destination $dest
```

# I've packed it into one script that elevates itself, 

so you can double-click it or right-click → **Run with PowerShell**, and accept the UAC prompt.**To use it:** save the file as `Backup-Drivers.ps1` (for example in `D:\Scripts`), then right-click → **Run with PowerShell**.

**What it does:**
- Elevates itself, so there's no need to open an admin terminal first.
- Exports all third-party drivers into a dated folder like `D:\DriverBackup\2026-10-10_1530`, so each run is kept separately.
- Writes a `driver-list.csv` into the backup showing what was exported, and prints the folder count and size.
- Deletes dated folders beyond the newest 5. Change `$KeepLast`, or set it to `0` to disable pruning. It only touches folders matching the date-name pattern inside `D:\DriverBackup`.

**Notes:**
- If double-clicking opens the file in an editor instead, that's a Windows default. Right-click → Run with PowerShell works, or you can make a desktop shortcut with the target `powershell.exe -ExecutionPolicy Bypass -File "D:\Scripts\Backup-Drivers.ps1"`.
- The script launches Windows PowerShell 5.1 (`powershell.exe`) rather than PowerShell 7, since the driver export cmdlets work most reliably there.
- From Nushell, you can run it with `powershell -File D:\Scripts\Backup-Drivers.ps1`.

I haven't run this on your machine, so test it once and check the output folder before relying on it. I can also add a zip step or a scheduled task for automatic weekly backups if you'd like.
