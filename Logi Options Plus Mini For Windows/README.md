# Logi Options+ mini for Windows

一款非官方的 Logitech Options+ 软件安装管理工具，帮助用户自定义安装 Logitech Options+，选择性启用/禁用特定功能模块，并提供配置备份、修复等功能。

## 功能特性

### 核心功能
- **安装管理** - 从 Logitech 官方服务器下载安装包（中国/海外 CDN 自动选择），支持静默安装
- **功能模块选择** - 12 个可选功能模块，可自定义安装内容
  - Quiet Install、Analytics、Flow、SSO、Update、DFU
  - Backlight、LogiVoice、AI Prompt Builder(Deprecated in Logi Options+ 2.7.961922)、Device Recommendation、Smart Actions、Actions Ring
- **卸载功能** - 完整卸载 Logi Options+
- **版本检测** - 检测当前已安装版本和最新版本

### 修复与配置
- **配置备份** - 安装前备份用户配置文件
- **配置恢复** - 安装后恢复用户配置文件
- **修复功能** - 扫描并删除损坏的配置文件

### 辅助功能
- **活动日志** - 实时显示安装过程的日志输出
- **安装进度** - 显示当前安装步骤和进度

## 技术栈

| 层级 | 技术选型 |
|------|----------|
| 框架 | Tauri 2.x |
| 后端语言 | Rust |
| 前端框架 | React 18 + TypeScript |
| UI 组件库 | shadcn/ui |
| 打包工具 | Tauri Bundler |

## 项目结构

```
logi-options-plus-mini/
├── src/                      # 前端源码
│   ├── App.tsx               # 主应用组件
│   ├── main.tsx              # 前端入口
│   ├── i18n.ts               # 国际化配置
│   ├── locales/              # 语言文件
│   │   ├── en.json
│   │   └── zh.json
│   └── components/           # UI 组件
├── src-tauri/                # Rust 后端
│   ├── src/
│   │   ├── main.rs           # Tauri 主入口
│   │   ├── lib.rs            # 库入口
│   │   ├── commands.rs       # Tauri 命令
│   │   ├── installer.rs      # 安装命令
│   │   ├── downloader.rs     # 下载命令
│   │   ├── version.rs        # 版本查询
│   │   ├── backup.rs         # 备份/恢复
│   │   ├── fixer.rs          # 修复命令
│   │   └── models.rs         # 数据模型
│   ├── Cargo.toml            # Rust 依赖
│   └── tauri.conf.json       # Tauri 配置
├── public/                   # 静态资源
├── index.html                # HTML 入口
├── vite.config.ts            # Vite 配置
└── package.json              # Node 依赖
```

## 开发环境

### 环境要求
- Node.js 18+
- Rust 1.70+
- Windows 10 20H2+ / Windows 11

### 安装依赖

```bash
pnpm install
```

### 开发模式

```bash
pnpm tauri dev
```

### 构建生产版本

```bash
pnpm tauri build
```

## 使用说明

1. 启动应用程序
2. 在功能模块列表中选择需要安装的组件
3. 查看当前版本和最新版本信息
4. 点击"安装/重装"按钮开始安装
5. 安装完成后可选择启动 Logi Options+



## 推荐 IDE 配置

- [VS Code](https://code.visualstudio.com/) + [Tauri](https://marketplace.visualstudio.com/items?itemName=tauri-apps.tauri-vscode) + [rust-analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer)

## 相关链接

- [Logi Options+ 官方支持](https://support.logi.com/hc/zh-cn/articles/37493733117847-Options-and-G-HUB-macOS-Certificate-Issue)
- [Tauri 官方文档](https://tauri.app/v1/guides/)
- [Logi Options+ 更新 API](https://updates.optionsplus.logitechg.com/pipeline/v2/update/optionsplus4/osx/public/update.json)
