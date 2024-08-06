#!/bin/sh
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
echo "##############################################################"
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

install_command="$package_unarchived_path/Contents/MacOS/$installer_name"

pushd "$package_unarchived_path"

# Configure backup
echo "$(date) | Backing up existing configuration..."
mv ~/Library/Application\ Support/LogiOptionsPlus ~/Library/Application\ Support/LogiOptionsPlus_bak

echo "$(date) | Uninstalling existing version of  $appname"
sudo $install_command --uninstall  >> /dev/null 2>&1

echo "$(date) | Restoring configuration from backup..."
mv ~/Library/Application\ Support/LogiOptionsPlus_bak ~/Library/Application\ Support/LogiOptionsPlus

# Installing...
# Change the following arguments to 'Yes' if you want to install the module.
# disable analytics、flow、sso、update、dfu、logivoice、aipromptbuilder、device-recommendation
echo "$(date) | Installing $appname..."
sudo $install_command --analytics No --flow No --sso No --update No --dfu No --logivoice No --aipromptbuilder No --device-recommendation No >> /dev/null 2>&1
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
