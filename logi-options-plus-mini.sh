#!/bin/bash
#set -x

############################################################################################
##
## Script to install latest Logi Options+ on macOS
##
###########################################

# Path.
package="logioptionsplus_installer"
downloaded_path="/private/tmp/logioptionsplus" #Path, from where the install operation happens.
downloaded_package_path="$downloaded_path/$package.zip"
package_unarchived_path="$downloaded_path/$package.app"
weburl="https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer.zip"
appname="Logi Options+"
installer_name="logioptionsplus_installer"

echo ""
echo "##############################################################"
echo "$(date) | Starting install of $appname"
echo "############################################################"
echo ""

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
curl -L -f -o "$downloaded_package_path" $weburl

# Unzip the Installer.
package_zip="$downloaded_package_path"
package_unzip="$downloaded_path"
echo "$(date) | Unarchiving $package_zip to $package_unzip..."
ditto -x -k "$package_zip" "$package_unzip"

# Installing...
echo "$(date) | Installing $appname..."
install_command="$package_unarchived_path/Contents/MacOS/$installer_name"

pushd "$package_unarchived_path"
echo "$(date) | Running installer $install_command"

# Configure backup
mv ~/Library/Application\ Support/LogiOptionsPlus ~/Library/Application\ Support/LogiOptionsPlus_bak
$install_command --uninstall
mv ~/Library/Application\ Support/LogiOptionsPlus_bak ~/Library/Application\ Support/LogiOptionsPlus

# disable analytics、flow、sso、update、dfu、logivoice、aipromptbuilder、device-recommendation
$install_command --analytics No --flow No --sso No --update No --dfu No --logivoice No --aipromptbuilder No --device-recommendation No
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
