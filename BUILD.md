# 构建 Lucky（内嵌前端单二进制）

把 ARTEX 0.3.30 源码品牌化为 **Lucky** 并编译成单个 Windows 可执行文件。

## 前置

| 组件 | 路径 | 说明 |
|---|---|---|
| Go 1.26.10 | `..\toolchain\go\bin\go.exe` | 静态编译，`CGO_ENABLED=0` |
| Node 24.17.0 | `..\toolchain\node-v24.17.0-win-x64\node.exe` | 仅构建期需要 |
| npm 11 | `..\toolchain\node-v24.17.0-win-x64\npm.cmd` | 首次会跑 `npm ci` |

## 一条命令

```powershell
.\build-lucky.ps1                 # 版本号默认 1.0.0
.\build-lucky.ps1 -Version 1.0.1  # 指定版本
.\build-lucky.ps1 -SkipInstall    # 依赖已装好，跳过 npm ci
```

产物：`dist\lucky.exe`（Windows amd64，内嵌前端，约 45 MB）

## 品牌改动只在三处

1. `web\src\config\app-config.ts` —— 产品名、公司名、标题、版权、登录账号名
2. `web\src\styles\presets\lucky.css` —— 主题色板（中性灰白 + #171717 主色 + 0.5rem 圆角）
3. `web\public\logo.png` / `logo.svg` / `src\app\favicon.ico` / `src\app\icon.png` —— 图标

图标由 `tools\gen_brand_assets.py` 生成（Pillow 绘制，改颜色/几何只改这个脚本）。

## 服务端品牌点

| 文件 | 内容 |
|---|---|
| `server\auth.go` | JWT subject 与登录账号名改为 `Lucky`（同时兼容旧 `ARTEX`） |
| `cmd\artex\main.go` | 启动横幅与监听日志 |
| `server\mcp_server.go` | MCP `serverInfo` 的 name/title |

## 许可提醒（AGPL-3.0）

本项目衍生自 ARTEX（AGPL-3.0）。对外提供网络服务时，须向使用者提供对应的完整源代码；
`LICENSE` 与界面中的「基于 ARTEX（AGPL-3.0）」署名必须保留。
