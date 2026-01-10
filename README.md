# Logi Options Plus Mini

[中文](README.md) | [English](README_EN.md)

**Logi Options+ mini** 提供了一种选择来自定义 Logi Options+，方便用户能够更好地控制其功能。

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

## 项目简介

参考官方[Logitech Options 软件的批量安装和配置](https://prosupport.logi.com/hc/zh-cn/articles/6046882446359-Logitech-Options-软件的批量安装和配置)

项目通过官方安装包命令行选项定制化Logi Options+功能。
支持macOS原生应用、macOS Shell、Windows PowerShell。

## 特性

- 定制化Logi Options+功能
- 易于使用的交互设计
- 卸载升级时自动保留配置
- 可定制功能
  - analytics 用户分享应用程序使用情况和诊断数据
  - flow
  - sso 用户登录应用程序的功能
  - update 应用程序更新
  - dfu 设备固件更新
  - logivoice 罗技语音功能
  - aipromptbuilder  AI Prompt Builder 功能（仅限macOS）
  - smartactions
  - actions-ring
  - device-recommendation 设备推荐功能（仅限macOS）

## 使用方法

### 使用 macOS 原生应用

下载最新版本 [here](https://v.qetesh.cc/d/Public/Logi%20Options%2B%20mini.dmg)

[<img width="64" alt="logi option plus1" src="https://github.com/user-attachments/assets/2c57172a-b1e3-4bab-abb8-6c60425ca640" />](https://v.qetesh.cc/d/Public/Logi%20Options%2B%20mini.dmg)

🔔 由于没有使用开发者证书签署应用，macOS可能会显示安全警告，需前往系统设置 → 隐私与安全 → 已阻止“Logi Options+mini”以保护Mac。然后点击“仍要打开”以运行该应用程序。

![WX20250305-181838@2x](https://github.com/user-attachments/assets/ca75fad3-b1e6-4b51-ba2c-f4b8e5770fb7)

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
  8. aipromptbuilder:       Enables or disables AI Prompt Builder feature.
  9. device-recommendation: Enables or disables device recommendation feature.
  10. smartactions:         Enables or disables Smart Actions feature.
  11. actions-ring:         Enables or disables Actions Ring feature.
  12. all
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
