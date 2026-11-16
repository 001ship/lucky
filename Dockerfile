# syntax=docker/dockerfile:1
#
# Lucky —— 多阶段自包含构建：前端静态导出 → Go 单二进制（go:embed 内嵌前端）→ 精简运行镜像。
# 直接 `docker build -t lucky:local .` 即可，无需预先准备二进制。

# ---------- 1) 前端 ----------
FROM node:22-bookworm-slim AS web
WORKDIR /src/web
COPY web/package.json web/package-lock.json ./
RUN npm ci --no-audit --no-fund --registry=https://registry.npmjs.org
COPY web/ ./
ENV NEXT_EXPORT=1 \
    NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1
RUN npm run build:static

# ---------- 2) 后端 ----------
FROM golang:1.26-bookworm AS build
WORKDIR /src
ENV CGO_ENABLED=0 \
    GOFLAGS=-mod=mod \
    GOPROXY=https://proxy.golang.org,direct
COPY go.mod go.sum ./
RUN go mod download
COPY . .
COPY --from=web /src/web/out ./server/webui/dist
ARG VERSION=dev
RUN go build -tags embedui -trimpath \
      -ldflags "-s -w -X main.version=${VERSION}" \
      -o /out/lucky ./cmd/artex

# ---------- 3) 运行 ----------
FROM debian:bookworm-slim
ARG TARGETARCH
ENV TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget jq unzip git tzdata \
      ripgrep dnsutils iputils-ping netcat-openbsd whois nmap \
      python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /out/lucky /app/lucky
COPY start.sh /app/start.sh
COPY skills/ /app/skills/
RUN chmod +x /app/lucky /app/start.sh \
    && mkdir -p /app/data

VOLUME ["/app/data"]
EXPOSE 8787 8788

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8787/ >/dev/null || exit 1

ENTRYPOINT ["/app/start.sh"]
CMD ["-addr", ":8787", "-proxy", ":8788"]