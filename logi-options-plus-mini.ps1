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

# Interactive Feature Selection
Write-Host ""
Write-Host "Please select the features you want to keep:"
Write-Host "1. analytics:             Shows or hides choice for users to opt in to share app usage and diagnostics data."
Write-Host "2. flow:                  Shows or hides the Flow feature. Default value is Yes"
Write-Host "3. sso:                   Shows or hides ability for users to sign into the app."
Write-Host "4. update:                Enables or disables app updates."
Write-Host "5. dfu:                   Enables or disables device firmware updates."
Write-Host "6. backlight:             Enables or disables keyboard backlight on the supported keyboards."
Write-Host "7. logivoice:             Enables or disables LogiVoice feature."
Write-Host "8. aipromptbuilder:       Enables or disables AI Prompt Builder feature."
Write-Host "9. device-recommendation: Enables or disables device recommendation feature."
Write-Host "10. smartactions:         Enables or disables Smart Actions feature."
Write-Host "11. actions-ring:         Enables or disables Actions Ring feature."
Write-Host "12. all"
Write-Host "Press enter for none"
Write-Host ""

# Get user input for feature selection
$selectedFeatures = Read-Host "Enter your choices (e.g. 2 6, default is none):"
if ($selectedFeatures -eq "") {
    $selectedFeatures = "none"
}

# Initialize all options as "No"
$analytics = "No"
$flow = "No"
$sso = "No"
$update = "No"
$dfu = "No"
$backlight = "No"
$logivoice = "No"
$aipromptbuilder = "No"
$device_recommendation = "No"
$smartactions = "No"
$actions_ring = "No"

# If "all" (11) is selected, set all options to "Yes"
if ($selectedFeatures -eq "11") {
    $analytics = "Yes"
    $flow = "Yes"
    $sso = "Yes"
    $update = "Yes"
    $dfu = "Yes"
    $backlight = "Yes"
    $logivoice = "Yes"
    $aipromptbuilder = "Yes"
    $device_recommendation = "Yes"
    $smartactions = "Yes"
    $actions_ring = "Yes"
} else {
    # Set selected options to "Yes"
    $featureList = $selectedFeatures -split " "
    foreach ($feature in $featureList) {
        switch ($feature) {
            "1" { $analytics = "Yes" }
            "2" { $flow = "Yes" }
            "3" { $sso = "Yes" }
            "4" { $update = "Yes" }
            "5" { $dfu = "Yes" }
            "6" { $backlight = "Yes" }
            "7" { $logivoice = "Yes" }
            "8" { $aipromptbuilder = "Yes" }
            "9" { $device_recommendation = "Yes" }
            "10" { $smartactions = "Yes" }
            "11" { $actions_ring = "Yes" }
            default { Write-Host "Invalid option: $feature" }
        }
    }
}

# Confirm settings with the user
Write-Host ""
Write-Host "Please confirm the following settings:"
Write-Host "analytics:                $analytics"
Write-Host "flow:                     $flow"
Write-Host "sso:                      $sso"
Write-Host "update:                   $update"
Write-Host "dfu:                      $dfu"
Write-Host "backlight:                $backlight"
Write-Host "logivoice:                $logivoice"
Write-Host "aipromptbuilder:          $aipromptbuilder"
Write-Host "device-recommendation:    $device_recommendation"
Write-Host "smartactions:             $smartactions"
Write-Host "actions-ring:             $actions_ring"
Write-Host ""

$confirm = Read-Host "Are these settings correct? [y/n](default: y)"
if ($confirm -ne "Y" -and $confirm -ne "y" -and $confirm -ne "") {
    Write-Host "$(Get-Date) | Installation cancelled."
    exit 1
}

# Install new version
Write-Host "$(Get-Date) | Installing $appName..."
$installArgs = "/analytics", $analytics, "/flow", $flow, "/sso", $sso, "/update", $update, "/dfu", $dfu, "/backlight", $backlight, "/logivoice", $logivoice, "/aipromptbuilder", $aipromptbuilder, "/device-recommendation", $device_recommendation, "/smartactions", $smartactions, "/actions-ring", $actions_ring
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