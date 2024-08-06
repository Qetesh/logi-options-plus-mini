# Script to install latest Logi Options+ on Windows

# Variables
$appName = "Logi Options+"
$installerName = "logioptionsplus_installer.exe"
$downloadUrl = "https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer.exe"
$downloadPath = "$env:TEMP\$installerName"
$configPath = "$env:LOCALAPPDATA\LogiOptionsPlus"
$backupPath = "$env:LOCALAPPDATA\LogiOptionsPlus_bak"

Write-Host ""
Write-Host "##############################################################"
Write-Host "$(Get-Date) | Starting install of $appName"
Write-Host "##############################################################"
Write-Host ""

# Download the installer
Write-Host "$(Get-Date) | Downloading $appName Installer..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath

# Check if download was successful
if (Test-Path $downloadPath) {
    Write-Host "$(Get-Date) | Download completed successfully."
} else {
    Write-Host "$(Get-Date) | Failed to download $appName installer."
    exit 1
}

# Backup existing configuration
if (Test-Path $configPath) {
    Write-Host "$(Get-Date) | Backing up existing configuration..."
    if (Test-Path $backupPath) {
        Remove-Item $backupPath -Recurse -Force
    }
    Copy-Item $configPath $backupPath -Recurse
    Write-Host "$(Get-Date) | Configuration backed up to $backupPath"
}

# Uninstall existing version
Write-Host "$(Get-Date) | Uninstalling existing version of $appName..."
Start-Process -FilePath $downloadPath -ArgumentList "/uninstall" -Wait -Verb RunAs

# Restore configuration backup
if (Test-Path $backupPath) {
    Write-Host "$(Get-Date) | Restoring configuration from backup..."
    if (Test-Path $configPath) {
        Remove-Item $configPath -Recurse -Force
    }
    Move-Item -Path $backupPath -Destination $configPath
    Write-Host "$(Get-Date) | Configuration restored from $backupPath"
}

# Change the following arguments to 'Yes' if you want to install the module.
# Install new version
Write-Host "$(Get-Date) | Installing $appName..."
$installArgs = "/analytics", "No", "/flow", "No", "/sso", "No", "/update", "No", "/dfu", "No", "/backlight", "No"
$process = Start-Process -FilePath $downloadPath -ArgumentList $installArgs -PassThru -Verb RunAs
$Handle = $process.Handle
$process.WaitForExit()

if ($process.ExitCode -eq 0) {
    Write-Host "$(Get-Date) | $appName installed successfully."
    # Clean up
    Remove-Item $downloadPath -Force
    Write-Host "$(Get-Date) | Cleaned up temporary files."
    Write-Host "Installation completed, press any key to exit..."
    [void][System.Console]::ReadKey($true)
    exit 0
} else {
    Write-Host "$(Get-Date) | Failed to install $appName. Exit code: $($process.ExitCode)"
    Write-Host "Installation completed, press any key to exit..."
    [void][System.Console]::ReadKey($true)
    exit 1
}