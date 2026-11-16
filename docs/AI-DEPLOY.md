# 交给 AI 自动部署：需要提供什么

把下面「一句话模板」连同你的实际情况发给 AI（或任意 coding agent），它就足够自主完成部署。
缺项会让它停下来问，所以尽量一次给全。

---

## 一、一句话模板（复制改占位符）

```
帮我部署 Lucky（https://github.com/001ship/lucky），要求如下：

【目标机器】<描述，见下>
【部署形态】Docker Compose / 原生单二进制 / Render / K8s（选一个）
【数据库】新建 PostgreSQL / 复用现有 <连接串或主机:端口、库名、用户、密码>
【对外访问】端口 8787，域名 <可选>，是否需要 HTTPS <是/否>
【LLM】provider=<openai|anthropic|兼容端点>，base_url=<可选>，model=<模型名>，key=<key>
【凭据】<SSH 私钥路径 或 已在该机器上 或 云平台 API token>
【验收】/login/ 返回 200；用日志里的 Setup token 完成管理员密码设置；建一个针对
        <靶场地址，如 http://127.0.0.1:3000（OWASP Juice Shop）> 的任务并能跑出至少 1 条 finding
【约束】保留旧版本可回滚；数据库改动前先 pg_dump；不要动 <已有服务/端口>。
```

---

## 二、目标机器怎么描述（决定它能不能动手）

**A. 就在本机（最简单）**
```
目标机器：当前这台 Windows 11，已有 PostgreSQL 17 在 127.0.0.1:5433（库 artex / 用户 artex），
已装 Docker Desktop。部署到 C:\app\lucky，端口 8787。
```
→ 它只需要这条 + 数据库密码，就能全程自动完成。

**B. 远程 Linux VM（需要 SSH）**
```
目标机器：ubuntu@1.2.3.4，端口 22，私钥在 C:\Users\me\.ssh\id_ed25519，
Ubuntu 24.04，2C4G，已装 docker + compose 插件，8080 已被占用，用 8787。
```
→ 最少需要：`地址 + 用户 + 私钥路径`（或密码，但私钥更安全）。

**C. 云平台托管（不需要服务器）**
```
用 Render 部署：给我一个新建的 Render API Key（或我点按钮你只负责验收）。
```
→ Render 的蓝图链接本身就是一键，AI 只需帮你核对环境变量与验收。

**D. Kubernetes**
```
目标：集群 kubeconfig 在 <路径>，namespace lucky，用 ghcr.io/001ship/lucky:latest，
需要 StatefulSet/Deployment + Service + Ingress，Postgres 用外部 <连接串>。
```

---

## 三、凭据清单（按需给，越小越好）

| 场景 | 需要给 | 不要给 |
|---|---|---|
| 本机部署 | 数据库密码（或 DSN） | 你的系统登录密码 |
| 远程 VM | SSH 私钥路径 / ssh-agent 已就绪 | 服务器 root 密码明文 |
| 拉私有代码 / 触发 CI | Fine-grained PAT：`Contents: Read`（+ 需要发版时 `Workflows: Write`），7 天过期 | 账号密码（Git 早已不支持）、全权限 classic token |
| 云平台 | Render/Railway 的 API Key（按项目最小权限） | 平台账号密码 |
| 运行时 LLM | `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / 兼容端点 key | — |

> 账号密码对 GitHub 的 Git 操作**完全没用**（2021 年起只接受 token/SSH），给了也用不上，还会泄漏。

---

## 四、它需要知道的“环境事实”（避免踩坑）

- 端口占用：`8787`（Web）、`8788`（流量录制代理）、数据库端口
- 是否已有 PostgreSQL 与版本；库/用户是否已存在
- 磁盘可用空间（镜像约 1.2 GB，`data/` 会随任务增长）
- 出网策略：能否访问 GitHub / ghcr.io / 你给的 LLM 端点
- 是否已有反向代理（nginx/Caddy）与证书

---

## 五、验收标准（写进需求里，AI 就会自证）

1. `curl -I http://<host>:8787/login/` → `200`
2. 日志出现 `Lucky <version> backend listening on <addr>`
3. `docker compose logs lucky | grep 'Setup token'` 能拿到令牌，`/setup` 设密成功
4. 登录账号名 `Lucky` 可进入控制台
5. 建一个靶场任务，`get_task`（或页面）能看到状态推进与至少 1 条 finding
6. 「系统配置 → MCP」可开启并生成令牌，`POST /mcp` 的 `tools/list` 返回 11 个工具
7. 回滚路径存在：旧版本目录/镜像 tag 保留，数据库备份文件已生成

---

## 六、给 AI 的一句“护栏”

```
约束：只在 <目标机器> 上操作；不要改动其他服务与端口；任何数据库变更前先备份；
涉及删除的操作先列清单等我确认；完成后输出：访问地址、管理员账号名、回滚步骤、遗留风险。
```
