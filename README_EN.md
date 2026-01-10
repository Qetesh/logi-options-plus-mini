# Logi Options Plus Mini
[中文](README.md) | [English](README_EN.md)

**Logi Options+ mini** Provides an option to customize Logi Options+ so that the user can better control its functions.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/11adddd4-bf0e-4e6d-b164-483b2521e228">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/user-attachments/assets/86024914-4650-4966-ba81-77d59fee5696">
  <img alt="Logi Options+ mini" src="https://github.com/user-attachments/assets/86024914-4650-4966-ba81-77d59fee5696" width="600" > 
</picture>

<img width="600" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/d4c503a9-51d8-4a18-af90-a3f3be508e8b">
<img width="600" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/14a85961-b022-4fc9-99bf-6e30b071f54c">
<img width="600" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/bf97e703-d5d5-43d6-9236-6e1d06b7c0c8">
<img width="600" alt="image" src="https://github.com/user-attachments/assets/66f8d2d7-5981-4085-9829-25c0189804a8">
<img width="600" alt="image" src="https://github.com/user-attachments/assets/d8918fd1-36f2-4933-9cc7-28471745139b">

## Project Overview
Refer to the official [Mass installation and configuration of Logitech Options+ software](https://prosupport.logi.com/hc/en-us/articles/6046882446359-Mass-installation-and-configuration-of-Logitech-Options-software)

This project customizes the Logi Options+ functionality through official installer command-line options. It supports macOS native applications, macOS Shell, and Windows PowerShell.

## Features

- customizes the Logi Options+ functionality
- Automatically retain configuration when uninstalling and upgrading
- Customizable features:
  - analytics: user sharing of application usage and diagnostic data
  - flow
  - sso: user login 
  - update: application updates
  - dfu: device firmware updates
  - logivoice: Logitech voice 
  - aipromptbuilder: AI Prompt Builder (macOS only)
  - smartactions
  - actions-ring
  - device-recommendation: device recommendation (macOS only)
- Easy-to-use

## Usage

### Using macOS Native Application

Download the latest version [here](https://github.com/Qetesh/logi-options-plus-mini/releases/latest)

[<img width="64" alt="logi option plus1" src="https://github.com/user-attachments/assets/2c57172a-b1e3-4bab-abb8-6c60425ca640" />](https://github.com/Qetesh/logi-options-plus-mini/releases/latest)

🔔 Due to the application not being signed with a developer certificate. macOS may show a security warning, simply go to System Settings → Privacy & Security → "Logi Options+mini"was blocked to protect your Mac. and click “Open Anyway” to run the app.

![WX20250305-181838@2x](https://github.com/user-attachments/assets/ca75fad3-b1e6-4b51-ba2c-f4b8e5770fb7)

### Using macOS Shell

1. Clone this project locally
    ```bash
    git clone https://github.com/Qetesh/logi-options-plus-mini.git
    cd logi-options-plus-mini
    ```

2. Run the shell script (requires `sudo` permission to uninstall the old version)
   - macOS
     ```bash
     chmod u+x logi-options-plus-mini.command
     ./logi-options-plus-mini.command

     ##############################################################
     2024年12月15日 星期日 23时32分33秒 +08 | Starting install of Logi Options+
     ##############################################################

     Please select the features you want to keep:
     1. analytics:             Shows or hides choice for users to opt in to share app usage and diagnostics data.
     2. flow:                  Shows or hides the Flow feature. Default value is Yes
     3. sso:                   Shows or hides ability for users to sign into the app.
     4. update:                Enables or disables app updates.
     5. dfu:                   Enables or disables device firmware updates.
     6. backlight:             Enables or disables keyboard backlight on the supported keyboards.
     7. logivoice:             Enables or disables LogiVoice feature.
     8. aipromptbuilder:       Enables or disables AI Prompt Builder feature.
     9. device-recommendation: Enables or disables device recommendation feature.
     10. smartactions:         Enables or disables Smart Actions feature.
     11. actions-ring:         Enables or disables Actions Ring feature.
     12. all
     Press enter for none

     Enter your choices(e.g. 2 6, default is none): 
     ```

   - Windows (Requires running the `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned` command once in an administrator terminal)

     Right-click on the ps1 script and "Run with PowerShell"
     ```powershell
     ##############################################################
     12/17/2024 19:50:23 | Starting install of Logi Options+
     ##############################################################
     12/17/2024 19:50:24 | Downloading Logi Options+ Installer...
     12/17/2024 19:51:06 | Download completed successfully.
     12/17/2024 19:51:06 | Uninstalling existing version of Logi Options+...

     Please select the features you want to keep:
     1. analytics:             Shows or hides choice for users to opt in to share app usage and diagnostics data.
     2. flow:                  Shows or hides the Flow feature. Default value is Yes
     3. sso:                   Shows or hides ability for users to sign into the app.
     4. update:                Enables or disables app updates.
     5. dfu:                   Enables or disables device firmware updates.
     6. backlight:             Enables or disables keyboard backlight on the supported keyboards.
     7. logivoice:             Enables or disables LogiVoice feature.
     8. aipromptbuilder:       Enables or disables AI Prompt Builder feature.
     9. device-recommendation: Enables or disables device recommendation feature.
     10. smartactions:         Enables or disables Smart Actions feature.
     11. actions-ring:         Enables or disables Actions Ring feature.
     12. all
     Press enter for none

     Enter your choices (e.g. 2 6, default is none):
     ```

   The script will automatically download the official installer and perform a streamlined installation.

## System Requirements

- macOS
- Windows
- Internet connection to download the official installer

## FAQ

- Some Macs cannot be uninstalled using the official method, and a third-party tool is required for uninstallation and then re-running. It has been tested that after using `Pearcleaner` for uninstallation, it can run normally after installation.

## Contributors

<a href="https://github.com/Qetesh/logi-options-plus-mini/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Qetesh/logi-options-plus-mini" />
</a>

## Contributing

Welcome to submit issues and requests. You can contribute code as follows:

1. Fork this repository
2. Create your branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the [Apache License](LICENSE).
