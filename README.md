# Logi Options Plus Mini
[中文版本](README.md) | [English Version](README_EN.md)

**Logi Options Plus Mini** 是一个精简版的Logi Options Plus，它只保留了对键盘和鼠标的支持，使得罗技键盘和鼠标的使用更加高效。
<img width="1518" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/d4c503a9-51d8-4a18-af90-a3f3be508e8b">
<img width="1518" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/14a85961-b022-4fc9-99bf-6e30b071f54c">
<img width="1518" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/bf97e703-d5d5-43d6-9236-6e1d06b7c0c8">
<img width="806" alt="image" src="https://github.com/user-attachments/assets/66f8d2d7-5981-4085-9829-25c0189804a8">
<img width="987" alt="image" src="https://github.com/user-attachments/assets/d8918fd1-36f2-4933-9cc7-28471745139b">

## 项目简介
参考官方[Logitech Options 软件的批量安装和配置](https://prosupport.logi.com/hc/zh-cn/articles/6046882446359-Logitech-Options-软件的批量安装和配置)

此项目通过一个Shell脚本 `logi-options-plus-mini.command` 实现，脚本会下载官方安装包，并使用命令行选项精简掉键盘、鼠标外的所有功能。

## 特性

- 仅保留键盘和鼠标功能
- 卸载升级时自动保留配置
- 去除无关功能，提升软件性能
  - analytics 用户分享应用程序使用情况和诊断数据
  - flow
  - sso 用户登录应用程序的功能
  - update 应用程序更新
  - dfu 设备固件更新
  - logivoice 罗技语音功能
  - aipromptbuilder  AI Prompt Builder 功能（仅限macOS）
  - smartactions
  - device-recommendation 设备推荐功能（仅限macOS）
- 易于使用的Shell脚本
  - 可修改shell文件中安装选项，添加需要的功能

## 使用方法

1. 克隆此项目到本地
    ```bash
    git clone https://github.com/Qetesh/logi-options-plus-mini.git
    cd logi-options-plus-mini
    ```

2. 运行Shell脚本（需要`sudo`权限卸载旧版本）
  - macOS
    ```bash
    chmod u+x logi-options-plus-mini.command
    ./logi-options-plus-mini.command

    ##############################################################
    2024年12月15日 星期日 23时32分33秒 +08 | Starting install of Logi Options+
    ##############################################################
    
    Please select the features you want to keep(e.g. 2 6, default is none):
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
    11. all
    Press enter for none
    
    Enter your choices: 
    ```
  - Windows（需要管理员终端运行一次`Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`）

    右键ps1脚本，`使用PowerShell运行`
    ```powershell
    ##############################################################
    12/17/2024 19:50:23 | Starting install of Logi Options+
    ##############################################################
    12/17/2024 19:50:24 | Downloading Logi Options+ Installer...
    12/17/2024 19:51:06 | Download completed successfully.
    12/17/2024 19:51:06 | Uninstalling existing version of Logi Options+...
    
    Please select the features you want to keep(e.g. 2 6, default is none):
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
    11. all
    Press enter for none
    
    Enter your choices (space-separated numbers):

    ```

脚本将会自动下载官方安装包，并进行精简安装。

## 系统要求

- macOS
- Windows
- 网络连接以下载官方安装包

## FAQ
- 部分Mac无法使用官方方式卸载，需使用第三方工具卸载后重新运行。已测试使用`Pearcleaner`卸载后可正常运行安装

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
