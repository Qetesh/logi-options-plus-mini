# Logi Options Plus Mini
[中文版本](README.md) | [English Version](README_EN.md)

**Logi Options Plus Mini** 是一个精简版的Logi Options Plus，它只保留了对键盘和鼠标的支持，使得罗技键盘和鼠标的使用更加高效。
<img width="1518" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/d4c503a9-51d8-4a18-af90-a3f3be508e8b">
<img width="1518" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/14a85961-b022-4fc9-99bf-6e30b071f54c">
<img width="1518" alt="image" src="https://github.com/Qetesh/logi-options-plus-mini/assets/4559341/bf97e703-d5d5-43d6-9236-6e1d06b7c0c8">
<img width="1059" alt="image" src="https://github.com/user-attachments/assets/a3700376-a4ba-44d3-b27b-116b0424b693">
<img width="928" alt="image" src="https://github.com/user-attachments/assets/4d555a79-9f95-455b-8ad4-a415f607c475">

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
    ```
  - Windows（需要管理员终端运行一次`Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`）

    右键ps1脚本，`使用PowerShell运行`

脚本将会自动下载官方安装包，并进行精简安装。

## 系统要求

- macOS
- Windows
- 网络连接以下载官方安装包

## 贡献

欢迎提交问题和请求。您可以通过以下方式贡献代码：

1. Fork 此仓库
2. 创建您的分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个Pull Request

## 许可证

此项目使用 [Apache 许可证](LICENSE)。
