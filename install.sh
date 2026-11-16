#!/bin/sh
# Lucky 一键部署（Linux / macOS，Docker 方式）
#
#   curl -fsSL https://raw.githubusercontent.com/__GH_REPO__/main/install.sh | sh
#
# 可选环境变量：
#   LUCKY_DIR     安装目录（默认 ./lucky）
#   LUCKY_IMAGE   使用已发布镜像（如 ghcr.io/owner/lucky:latest），不填则本地构建
#   LUCKY_PORT    Web 端口（默认 8787）
#   LUCKY_TAG     镜像 tag（配合 LUCKY_IMAGE，默认 latest）
set -eu

REPO="${LUCKY_REPO:-__GH_REPO__}"
DIR="${LUCKY_DIR:-./lucky}"
PORT="${LUCKY_PORT:-8787}"
IMAGE="${LUCKY_IMAGE:-}"
TAG="${LUCKY_TAG:-latest}"

say()  { printf '\033[36m[lucky]\033[0m %s\n' "$*"; }
die()  { printf '\033[31m[lucky]\033[0m %s\n' "$*" >&2; exit 1; }

# ---- 1) 依赖检查 ----
command -v docker >/dev/null 2>&1 || die "未检测到 docker，请先安装 Docker Engine / Docker Desktop"
if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  die "未检测到 docker compose 插件，请升级 Docker 或安装 docker-compose"
fi
say "使用 $($COMPOSE --version 2>/dev/null || echo "$COMPOSE")"

# ---- 2) 取源码 ----
if [ -f "$DIR/docker-compose.yml" ]; then
  say "复用已有目录 $DIR"
else
  command -v tar >/dev/null 2>&1 || die "缺少 tar"
  mkdir -p "$DIR"
  say "下载源码 $REPO ..."
  TARBALL="$(mktemp)"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/main" -o "$TARBALL" || die "下载失败"
  else
    wget -qO "$TARBALL" "https://codeload.github.com/$REPO/tar.gz/refs/heads/main" || die "下载失败"
  fi
  tar -xzf "$TARBALL" -C "$DIR" --strip-components=1
  rm -f "$TARBALL"
fi
cd "$DIR"

# ---- 3) 生成 .env ----
if [ ! -f .env ]; then
  PW="$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24)"
  cat > .env <<EOF
POSTGRES_USER=artex
POSTGRES_PASSWORD=$PW
POSTGRES_DB=artex
LUCKY_PORT=$PORT
LUCKY_IMAGE=$IMAGE
LUCKY_TAG=$TAG
EOF
  say "已生成 .env（数据库密码已随机化）"
else
  say "复用已有 .env"
fi

# ---- 4) 起服务 ----
if [ -n "$IMAGE" ]; then
  say "拉取镜像 $IMAGE:$TAG"
  $COMPOSE pull lucky
  $COMPOSE up -d
else
  say "本地构建并启动（首次约 3-6 分钟）"
  $COMPOSE up -d --build
fi

# ---- 5) 等就绪 ----
say "等待服务就绪 ..."
i=0
while [ "$i" -lt 60 ]; do
  if curl -fsS "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then break; fi
  i=$((i + 1)); sleep 2
done

TOKEN="$($COMPOSE logs lucky 2>/dev/null | grep -F '[auth]' | grep -o 'Setup token:.*' | tail -n1 | sed 's/Setup token: *//' || true)"

cat <<EOF

  Lucky 已启动
  ├─ 控制台： http://127.0.0.1:$PORT
  ├─ 初始化： http://127.0.0.1:$PORT/setup
  ├─ 设定令牌：${TOKEN:- 见 docker compose logs lucky | grep auth}
  └─ 日志：    $COMPOSE logs -f lucky

  数据目录：$PWD/data    数据库卷：lucky_pgdata
  停止：$COMPOSE down      卸载（含数据）：$COMPOSE down -v

EOF