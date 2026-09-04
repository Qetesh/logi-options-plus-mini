# Logi Options Plus Mini

[中文](README.md) | [English](README_EN.md)

**Logi Options+ mini** 提供了一种选择来自定义 Logi Options+，方便用户能够更好地控制其功能。

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/11adddd4-bf0e-4e6d-b164-483b2521e228">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/user-attachments/assets/86024914-4650-4966-ba81-77d59fee5696">
  <img alt="Logi Options+ mini" src="https://github.com/user-attachments/assets/86024914-4650-4966-ba81-77d59fee5696" width="600" > 
</picture>

<img width="600" src="https://github.com/user-attachments/assets/5121e1c2-d4bb-4300-b107-511d4be6e2bf" />

<img width="600" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/d4c503a9-51d8-4a18-af90-a3f3be508e8b">
<img width="600" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/14a85961-b022-4fc9-99bf-6e30b071f54c">
<img width="600" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/bf97e703-d5d5-43d6-9236-6e1d06b7c0c8">
<img width="600" alt="image" src="https://github.com/user-attachments/assets/66f8d2d7-5981-4085-9829-25c0189804a8">
<img width="600" alt="image" src="https://github.com/user-attachments/assets/d8918fd1-36f2-4933-9cc7-28471745139b">

## 项目简介

参考官方[Logitech Options 软件的批量安装和配置](https://prosupport.logi.com/hc/zh-cn/articles/6046882446359-Logitech-Options-软件的批量安装和配置)

项目通过官方安装包命令行选项定制化 Logi Options+ 功能。
支持 macOS 原生应用、Windows 原生应用，以及 macOS Shell / Windows PowerShell 脚本。

> **免责声明**：本项目为非官方第三方工具，与 Logitech 无任何关联。Logi、Logitech、Options+ 等为 Logitech 的商标。

## 仓库结构

| 目录 / 文件 | 说明 |
|-------------|------|
| [`Logi Options Plus Mini/`](Logi%20Options%20Plus%20Mini/) | **macOS 原生应用** — SwiftUI + Xcode 工程，含 GUI 安装器、配置备份、权限检测、后台 Agent 等 |
| [`Logi Options Plus Mini For Windows/`](Logi%20Options%20Plus%20Mini%20For%20Windows/) | **Windows 原生应用** — Tauri 2 + React + Rust，功能与 macOS 版对齐 |
| `logi-options-plus-mini.command` | macOS 命令行安装脚本 |
| `logi-options-plus-mini.ps1` | Windows PowerShell 安装脚本 |
| `appcast.xml` | macOS Sparkle 自动更新源 |
| `latest.json` | Windows Tauri 自动更新源 |

### 从源码构建

**macOS**：用 Xcode 打开 `Logi Options Plus Mini/Logi Options+ mini.xcodeproj`，在 Signing 中设置你的 Development Team 后构建。

**Windows**：进入 `Logi Options Plus Mini For Windows/`，执行 `pnpm install && pnpm tauri dev`（开发）或 `pnpm tauri build`（发布）。详见该目录下的 [README](Logi%20Options%20Plus%20Mini%20For%20Windows/README.md)。

## 特性

- 定制化Logi Options+功能
- 易于使用的交互体验
- 卸载升级时自动保留配置
- 支持安装离线版Logi Options+
- 可定制功能
  - analytics 用户分享应用程序使用情况和诊断数据
  - flow
  - sso 用户登录应用程序的功能
  - update 应用程序更新
  - dfu 设备固件更新
  - logivoice 罗技语音功能
  - aipromptbuilder AI Prompt Builder 功能（仅限 Windows）
  - smartactions
  - actions-ring
  - device-recommendation 设备推荐功能（仅限macOS）

## 使用方法

### 使用 macOS 原生应用

下载最新版本 [GitHub Releases](https://github.com/Qetesh/logi-options-plus-mini/releases/latest)

[<img width="64" alt="logi option plus1" src="https://github.com/user-attachments/assets/2c57172a-b1e3-4bab-abb8-6c60425ca640" />](https://github.com/Qetesh/logi-options-plus-mini/releases/latest)

### 使用 Windows 原生应用

从 [GitHub Releases](https://github.com/Qetesh/logi-options-plus-mini/releases/latest) 下载 Windows 安装包。源码位于 [`Logi Options Plus Mini For Windows/`](Logi%20Options%20Plus%20Mini%20For%20Windows/)，详见该目录 [README](Logi%20Options%20Plus%20Mini%20For%20Windows/README.md)。

### 使用 macOS Shell

1. 克隆此项目到本地

   ```bash
   git clone https://github.com/Qetesh/logi-options-plus-mini.git
   cd logi-options-plus-mini
   ```
2. 运行Shell脚本（需要 `sudo`权限卸载旧版本）

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
  8. device-recommendation: Enables or disables device recommendation feature.
  9. smartactions:          Enables or disables Smart Actions feature.
  10. actions-ring:         Enables or disables Actions Ring feature.
  11. all
  Press enter for none

  Enter your choices(e.g. 2 6, default is none): 
  ```
- Windows（需要管理员终端运行一次 `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`，具体见：[#5](https://github.com/Qetesh/logi-options-plus-mini/issues/5)）

  右键ps1脚本，`使用PowerShell运行`

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

  Enter your choices(e.g. 2 6, default is none):

  ```

脚本将会自动下载官方安装包，并进行精简安装。

## 系统要求

- macOS
- Windows
- 网络连接以下载官方安装包

## FAQ

- 部分Mac无法使用官方方式卸载，需使用第三方工具卸载后重新运行。已测试使用 `Pearcleaner`卸载后可正常运行安装

### Contributors

<a href="https://github.com/Qetesh/logi-options-plus-mini/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Qetesh/logi-options-plus-mini" />
</a>

## 贡献

欢迎提交问题和请求。您可以通过以下方式贡献代码：

1. Fork 此仓库
2. 创建您的分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个Pull Request

## 许可证

此项目使用 [Apache 许可证](LICENSE)。
