# Lucky 构建脚本：前端静态导出 + 内嵌单二进制
# 用法：.\build-lucky.ps1 [-Version 1.0.0] [-SkipInstall]

param(
  [string]$Version = "1.0.0",
  [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$toolchain = Join-Path (Split-Path $root -Parent) "toolchain"
$go = Join-Path $toolchain "go\bin\go.exe"
$nodeDir = Join-Path $toolchain "node-v24.17.0-win-x64"
$npm = Join-Path $nodeDir "npm.cmd"

foreach ($p in @($go, $npm)) {
  if (-not (Test-Path $p)) { throw "缺少构建工具：$p" }
}

$env:PATH = "$nodeDir;$env:PATH"
$env:GOPROXY = "https://goproxy.cn,direct"
$env:GOSUMDB = "off"
$env:CGO_ENABLED = "0"
# 默认 GOPATH（%USERPROFILE%\go）在本机不可创建，统一落到工具链目录
$env:GOPATH = Join-Path $toolchain "gopath"
$env:GOMODCACHE = Join-Path $env:GOPATH "pkg\mod"
$env:GOCACHE = Join-Path $toolchain "gocache"

Push-Location (Join-Path $root "web")
try {
  if (-not $SkipInstall -or -not (Test-Path "node_modules")) {
    Write-Host "[1/4] npm ci ..." -ForegroundColor Cyan
    & $npm ci --no-audit --no-fund
    if ($LASTEXITCODE -ne 0) { throw "npm ci 失败" }
  } else {
    Write-Host "[1/4] 跳过依赖安装" -ForegroundColor DarkGray
  }

  Write-Host "[2/4] 前端静态导出（NEXT_EXPORT=1）..." -ForegroundColor Cyan
  $env:NEXT_EXPORT = "1"
  $env:NODE_ENV = "production"
  & (Join-Path $nodeDir "node.exe") (Join-Path $PWD "node_modules\next\dist\bin\next") build
  if ($LASTEXITCODE -ne 0) { throw "next build 失败" }
} finally {
  Pop-Location
}

$out = Join-Path $root "web\out"
if (-not (Test-Path $out)) { throw "未生成 web\out" }

$dist = Join-Path $root "server\webui\dist"
if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Force -Path $dist | Out-Null
Copy-Item "$out\*" $dist -Recurse -Force
$files = (Get-ChildItem $dist -Recurse -File | Measure-Object).Count
Write-Host "[3/4] 前端产物已同步到 server\webui\dist（$files 个文件）" -ForegroundColor Cyan

$bin = Join-Path $root "dist"
New-Item -ItemType Directory -Force -Path $bin | Out-Null
$exe = Join-Path $bin "lucky.exe"
Write-Host "[4/4] go build -tags embedui（version=$Version）..." -ForegroundColor Cyan
Push-Location $root
try {
  & $go build -tags embedui -trimpath `
    -ldflags "-s -w -X main.version=$Version" `
    -o $exe ./cmd/artex
  if ($LASTEXITCODE -ne 0) { throw "go build 失败" }
} finally {
  Pop-Location
}

$size = (Get-Item $exe).Length / 1MB
Write-Host ("完成：{0}（{1:N1} MB）" -f $exe, $size) -ForegroundColor Green
