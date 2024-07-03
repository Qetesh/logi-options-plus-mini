# Logi Options Plus Mini
[中文版本](README.md) | [English Version](README_EN.md)

**Logi Options Plus Mini** is a streamlined version of Logi Options Plus that only supports keyboards and mice, making Logitech keyboards and mice more efficient to use.
<img width="1518" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/d4c503a9-51d8-4a18-af90-a3f3be508e8b">
<img width="1518" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/14a85961-b022-4fc9-99bf-6e30b071f54c">
<img width="1518" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/bf97e703-d5d5-43d6-9236-6e1d06b7c0c8">

## Project Overview

This project is implemented through a shell script `logi-options-plus-mini.sh`, which downloads the official installer and streamlines it by removing all functions except for keyboard and mouse.

## Features

- Only supports keyboards and mice
- Removes unnecessary features to improve software performance
  - analytics: user sharing of application usage and diagnostic data
  - flow
  - sso: user login 
  - update: application updates
  - dfu: device firmware updates
  - logivoice: Logitech voice 
  - aipromptbuilder: AI Prompt Builder 
  - device-recommendation: device recommendation 
- Easy-to-use shell script
  - You can modify the installation options in the shell file to add needed features

## Usage

1. Clone this project locally
    ```bash
    git clone https://github.com/Qetesh/logi-options-plus-mini.git
    cd logi-options-plus-mini
    ```

2. Run the shell script (requires `sudo` permission to uninstall the old version)
    ```bash
    sudo ./logi-options-plus-mini.sh
    ```

The script will automatically download the official installer and perform a streamlined installation.

## System Requirements

- macOS system
- Internet connection to download the official installer

## Contributing

Feel free to submit issues and requests. You can contribute code as follows:

1. Fork this repository
2. Create your branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the [Apache License](LICENSE).
