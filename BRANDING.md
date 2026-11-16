# Lucky 品牌化改造说明

- 产品名：**Lucky**
- 公司名：**any**
- 视觉：中性灰白 + 近黑主色（`#171717`）+ 1px 细边框 + 0.5rem 圆角 + Inter 字体（对齐 `app.etugen.io` 的极简企业风）
- 上游：ARTEX v0.3.30（`RuoJi6/ARTEX`，AGPL-3.0），源码在 `C:\Users\111111\Desktop\999\lucky`
- 构建：`.\build-lucky.ps1`（见 [BUILD.md](BUILD.md)），产物 `dist\lucky.exe`（41.7 MB，前端已内嵌）

---

## 一、改了哪些地方

### 1. 品牌中枢：`web/src/config/app-config.ts`

| 字段 | 值 |
|---|---|
| `name` | `Lucky` |
| `company` | `any` |
| `authUsername` | `Lucky`（登录账号名，服务端同步校验） |
| `copyright` | `© 2026, any. All rights reserved.` |
| `attribution` | `Based on ARTEX (AGPL-3.0)`（AGPL 要求的署名，保留） |
| `meta.title` | `Lucky — 自主渗透测试控制台` |
| `meta.description` | `由 any 出品的 LLM 多智能体自主渗透测试平台` |

侧边栏名称、浏览器标题、登录页文案都从这里取；**后续换真名只需改这一个文件 + 重新构建**。

### 2. 主题：新增 `web/src/styles/presets/lucky.css`

| 令牌 | 浅色 | 深色 |
|---|---|---|
| `--background` | `#ffffff` | `#0a0a0a` |
| `--foreground` | `#0a0a0a` | `#fafafa` |
| `--primary` | `#171717` | `#fafafa` |
| `--secondary` / `--muted` / `--accent` | `#f5f5f5` | `#262626` |
| `--border` / `--input` | `#e5e5e5` | `#262626` |
| `--ring` | `#a1a1a1` | `#737373` |
| `--destructive` | `#e40014` | `#ff5c5c` |
| `--sidebar` | `#fafafa` | `#0f0f0f` |
| `--radius` | `0.5rem` | `0.5rem` |

- `lib/preferences/theme.ts`：预设列表新增 `Lucky`（默认选中）
- `lib/preferences/preferences-config.ts`：`theme_preset="lucky"`、`font="inter"`、`theme_mode="light"`
- `app/globals.css`：`@import "../styles/presets/lucky.css"`

### 3. 图标

由 `tools/gen_brand_assets.py` 生成（Pillow 绘制，单色 L 字标，透明底）：

| 文件 | 用途 |
|---|---|
| `web/public/logo.png`（1024²，8.7 KB） | 登录页左栏 + 侧边栏 |
| `web/public/logo.svg`（282 B） | 文档/外链用矢量版 |
| `web/src/app/icon.png`（512²） | 浏览器标签图标 |
| `web/src/app/favicon.ico`（16/32/48/64） | 传统 favicon |

登录页左栏是 `bg-primary`（近黑）+ `brightness-0 invert`，所以单色透明图标会自动反白，不需要第二套素材。

### 4. 界面文案

`web/src/i18n/*.ts` 共 8 个语言资源文件里的 `ARTEX` 全部替换为 `Lucky`，包括：
登录问候、初始化向导、设置页 20+ 处说明、使用须知/免责声明、通知模板、错误提示。
其余同义替换：`artex@example.com → lucky@example.com`、`https://artex.example.com → https://lucky.example.com`、
`docker compose pull artex → lucky`、mock 日志行 → `Lucky v1.0.0 backend listening ...`。

### 5. 服务端

| 文件 | 改动 |
|---|---|
| `server/auth.go` | JWT `Subject` 与登录校验改为 `Lucky`，**同时兼容旧 `ARTEX`**（既有脚本不会失效） |
| `cmd/artex/main.go` | 启动横幅改为 codepage 安全的纯 ASCII（`Lucky  -  any` + `v1.0.0 . windows/amd64 ... listening`），避免 GBK 控制台乱码 |
| `server/mcp_server.go` | MCP `serverInfo` 的 `name/title` → `lucky/Lucky` |
| `docker-compose.yml` | 服务名 `artex → lucky`，镜像变量 `LUCKY_IMAGE/LUCKY_TAG` |

**刻意保留（不影响用户可见）**：Go module 路径 `github.com/Autumn-27/artex`、环境变量 `ARTEX_*`、
内部存储键 `artex_token` / `artex_locale` / `artex.*` 偏好键、可执行文件名相关的 selfupdate 协议。
改名这些只会带来迁移成本和登录态丢失，不产生商业价值。

---

## 二、部署现状

| 项目 | 值 |
|---|---|
| 安装目录 | `C:\Users\111111\Desktop\999\artex-deploy\bin\lucky-1.0.0-windows-amd64` |
| 进程 | `lucky.exe`（单进程，PID 随重启变化） |
| 端口 | `127.0.0.1:8787`（Web/API/SSE）、`127.0.0.1:8788`（录制代理） |
| 版本 | `1.0.0`（`-ldflags -X main.version=1.0.0`） |
| 数据库 | PostgreSQL `127.0.0.1:5433/artex`（沿用，schema 未变） |
| 登录账号 | `Lucky`（旧 `ARTEX` 仍可登录），密码不变 |
| 启动链 | 计划任务 `ARTEX` → `start-all.bat`（PG 守护 + `lucky.exe` 退避重启） |
| 回滚 | 旧目录 `bin\artex-0.3.30-windows-amd64`（把 `start-all.bat` 的 `APP` 改回即可） |

已验证：`/` 与 `/login/` 返回 200；页面标题 `Lucky — 自主渗透测试控制台`；登录页 HTML 中已无 `ARTEX`；
`tasks=1 / findings=4 / assets=87 / agents=11` 数据完好；`/api/auth/login` 对 `Lucky` 与 `ARTEX` 都返回 401（密码错误，说明账号名通过校验）。

---

## 三、下一步可做的品牌深化

1. **换真名**：改 `app-config.ts` 的 `name/company/meta` + 用 `tools/gen_brand_assets.py` 重出图标 + `.\build-lucky.ps1`
2. **可执行文件名**：`lucky.exe` 已完成；若要连进程名/服务名一起改，同步 `start.bat`、`start-all.bat`、`update.sh`
3. **登录账号名**：若要改成公司域名风格（如 `admin`），改 `server/auth.go` 的校验串与 `app-config.ts:authUsername`
4. **关于页/页脚**：当前 `copyright` 字段已在配置里但没有落页面，可在 `app/(main)/_components/sidebar` 或设置页加一个「关于 Lucky」卡片
5. **导出物页眉**：报告/CSV 的页眉目前取前端文案，若要做成「Lucky Security Report」样式，改 `web/src/i18n/task-messages.ts` 的报告标题键

## 四、合规提醒

Lucky 衍生自 ARTEX（AGPL-3.0）：
- 对外提供网络服务时，必须向使用者提供**对应的完整源代码**（自建一个对内可访问的源码分发方式即可）
- `LICENSE` 与界面文案中的 `Based on ARTEX (AGPL-3.0)` 署名不能删
- 商业化收费本身完全允许（AGPL 不禁止售卖），受约束的只是源码可得性
