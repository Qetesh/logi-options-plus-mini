#!/bin/sh
#set -x

############################################################################################
##
## Script to install latest Logi Options+ on macOS
##
###############################################

# Path.
package="logioptionsplus_installer"
downloaded_path="/private/tmp/logioptionsplus" #Path, from where the install operation happens.
downloaded_package_path="$downloaded_path/$package.zip"
package_unarchived_path="$downloaded_path/$package.app"
weburl="https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer.zip"
appname="Logi Options+"
installer_name="logioptionsplus_installer"
install_path="$package_unarchived_path/Contents/MacOS/$installer_name"

echo ""
echo "##############################################################"
echo "$(date) | Starting install of $appname"
echo "##############################################################"
echo ""
echo "Please select the features you want to keep:"
echo "1. analytics:             Shows or hides choice for users to opt in to share app usage and diagnostics data."
echo "2. flow:                  Shows or hides the Flow feature. Default value is Yes"
echo "3. sso:                   Shows or hides ability for users to sign into the app."
echo "4. update:                Enables or disables app updates."
echo "5. dfu:                   Enables or disables device firmware updates."
echo "6. backlight:             Enables or disables keyboard backlight on the supported keyboards."
echo "7. logivoice:             Enables or disables LogiVoice feature."
echo "8. aipromptbuilder:       Enables or disables AI Prompt Builder feature."
echo "9. device-recommendation: Enables or disables device recommendation feature."
echo "10. smartactions:         Enables or disables Smart Actions feature."
echo "11. all"
echo "Press enter for none"
echo ""

read -p "Enter your choices(e.g. 2 6, default is none): " features

# Initialize all options as "No"
analytics="No"
flow="No"
sso="No"
update="No"
dfu="No"
backlight="No"
logivoice="No"
aipromptbuilder="No"
device_recommendation="No"
smartactions="No"

# If "all" (11) is selected, set all options to "Yes"
if [[ "$features" == *11* ]]; then
  analytics="Yes"
  flow="Yes"
  sso="Yes"
  update="Yes"
  dfu="Yes"
  backlight="Yes"
  logivoice="Yes"
  aipromptbuilder="Yes"
  device_recommendation="Yes"
  smartactions="Yes"
else
  # Set selected options to "Yes"
  for feature in $features; do
    case $feature in
      1) analytics="Yes" ;;
      2) flow="Yes" ;;
      3) sso="Yes" ;;
      4) update="Yes" ;;
      5) dfu="Yes" ;;
      6) backlight="Yes" ;;
      7) logivoice="Yes" ;;
      8) aipromptbuilder="Yes" ;;
      9) device_recommendation="Yes" ;;
      10) smartactions="Yes" ;;
      *) echo "Invalid option: $feature";;
    esac
  done
fi


echo "Please confirm the following settings:"
echo "analytics:                $analytics"
echo "flow:                     $flow"
echo "sso:                      $sso"
echo "update:                   $update"
echo "dfu:                      $dfu"
echo "backlight:                $backlight"
echo "logivoice:                $logivoice"
echo "aipromptbuilder:          $aipromptbuilder"
echo "device-recommendation:    $device_recommendation"
echo "smartactions:             $smartactions"
echo ""

read -p "Are these settings correct? [y/n](default: y): " confirm
if [[ $confirm != "Y" && $confirm != "y" && $confirm != "" ]]; then
    echo "Installation cancelled."
    exit 1
fi

pushd "/private/tmp"
if [ -d "$downloaded_path" ]; then
    echo "$(date) | Cleaning up previous cache."
    rm -rf logioptionsplus
fi

echo "$(date) | Creating $downloaded_path directory..."
mkdir -p logioptionsplus
popd

# Downloading the Installer.
echo "$(date) | Downloading $appname Installer..."
curl -L -f -o "$downloaded_package_path" "$weburl" || { echo "Failed to download installer"; exit 1; }

# Unzip the Installer.
package_zip="$downloaded_package_path"
package_unzip="$downloaded_path"
echo "$(date) | Unarchiving $package_zip to $package_unzip..."
ditto -x -k "$package_zip" "$package_unzip" || { echo "Failed to unzip installer"; exit 1; }

pushd "$package_unarchived_path"

# Configure backup
echo "$(date) | Backing up existing configuration..."
mv ~/Library/Application\ Support/LogiOptionsPlus ~/Library/Application\ Support/LogiOptionsPlus_bak

echo "$(date) | Uninstalling existing version of $appname"
uninstall_command="$install_path --uninstall"
echo "Executing: $uninstall_command"
sudo $uninstall_command >> /dev/null 2>&1

echo "$(date) | Restoring configuration from backup..."
mv ~/Library/Application\ Support/LogiOptionsPlus_bak ~/Library/Application\ Support/LogiOptionsPlus

# Installing...
# Change the following arguments to 'Yes' if you want to install the module.
# disable analytics,flow,sso,update,dfu,logivoice,aipromptbuilder,device-recommendation,smartactions
echo "$(date) | Installing $appname..."

# Construct the install command with selected options
install_command="$install_path --analytics $analytics --flow $flow --sso $sso --update $update --dfu $dfu --backlight $backlight --logivoice $logivoice --aipromptbuilder $aipromptbuilder --device-recommendation $device_recommendation --smartactions $smartactions"
echo "Executing: $install_command"

sudo $install_command >> /dev/null 2>&1
popd

if [ "$?" = "0" ]; then
    echo "$(date) | $appname Installed successfully."
    echo "$(date) | Cleaning Up"
    rm -rf $package_zip $package_unzip $downloaded_path
    echo "$(date) | $appname Installed successfully."
    exit 0
else
    # Something went wrong here, either the download failed or the install Failed
    # intune will pick up the exit status and the IT Pro can use that to determine what went wrong.
    # Intune can also return the log file if requested by the admin
    echo "$(date) |  Failed to install $appname"
    exit -1
fi
