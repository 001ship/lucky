<#
.SYNOPSIS
  Lucky 一键部署（Windows）

.DESCRIPTION
  Docker 方式（默认，推荐）：
      irm https://raw.githubusercontent.com/001ship/lucky/main/install.ps1 | iex

  原生方式（已有 PostgreSQL，直接跑单二进制）：
      .\install.ps1 -Native -PgHost 127.0.0.1 -PgPort 5432 -PgUser artex -PgPassword 'xxx'

.PARAMETER Native
  不依赖 Docker，下载 release 里的 lucky.exe 并本地启动。

.PARAMETER Dir
  安装目录，默认 %LOCALAPPDATA%\Lucky
#>
[CmdletBinding()]
param(
  [switch]$Native,
  [string]$Repo = "001ship/lucky",
  [string]$Dir = "$env:LOCALAPPDATA\Lucky",
  [int]$Port = 8787,
  [string]$PgHost = "127.0.0.1",
  [int]$PgPort = 5432,
  [string]$PgUser = "artex",
  [string]$PgPassword = "",
  [string]$PgDb = "artex"
)

$ErrorActionPreference = "Stop"
function Say($m) { Write-Host "[lucky] $m" -ForegroundColor Cyan }
function Die($m) { Write-Host "[lucky] $m" -ForegroundColor Red; exit 1 }

New-Item -ItemType Directory -Force -Path $Dir | Out-Null

if (-not $Native) {
  # ---------- Docker 方式 ----------
  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Die "未检测到 Docker。请安装 Docker Desktop，或改用 -Native 参数配已有 PostgreSQL。"
  }
  docker compose version *> $null
  if ($LASTEXITCODE -ne 0) { Die "未检测到 docker compose 插件，请升级 Docker Desktop。" }

  if (-not (Test-Path "$Dir\docker-compose.yml")) {
    Say "下载源码 ..."
    $zip = Join-Path $env:TEMP "lucky-src.zip"
    Invoke-WebRequest "https://codeload.github.com/$Repo/zip/refs/heads/main" -OutFile $zip -UseBasicParsing
    Expand-Archive $zip -DestinationPath "$Dir\_src" -Force
    $inner = Get-ChildItem "$Dir\_src" -Directory | Select-Object -First 1
    Copy-Item "$inner\*" $Dir -Recurse -Force
    Remove-Item "$Dir\_src", $zip -Recurse -Force -ErrorAction SilentlyContinue
  }

  $envFile = Join-Path $Dir ".env"
  if (-not (Test-Path $envFile)) {
    $pw = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
    @"
POSTGRES_USER=artex
POSTGRES_PASSWORD=$pw
POSTGRES_DB=artex
LUCKY_PORT=$Port
"@ | Set-Content -Path $envFile -Encoding utf8
    Say "已生成 .env（数据库密码随机化）"
  }

  Say "构建并启动容器（首次 3-6 分钟）..."
  Push-Location $Dir
  try {
    docker compose up -d --build
    if ($LASTEXITCODE -ne 0) { Die "docker compose 启动失败" }
  } finally { Pop-Location }

  Start-Sleep -Seconds 8
  $token = (docker compose -f "$Dir\docker-compose.yml" logs lucky 2>$null | Select-String -Pattern 'Setup token:') -replace '.*Setup token:\s*', ''
  Write-Host ""
  Write-Host "  Lucky 已启动" -ForegroundColor Green
  Write-Host "  控制台：  http://127.0.0.1:$Port"
  Write-Host "  初始化：  http://127.0.0.1:$Port/setup"
  Write-Host "  设定令牌：$($token -join ' ')"
  return
}

# ---------- 原生方式 ----------
Say "获取最新 release ..."
$rel = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
$asset = $rel.assets | Where-Object { $_.name -like "*windows-amd64.zip" } | Select-Object -First 1
if (-not $asset) { Die "该 release 没有 windows-amd64 资产" }
$zipPath = Join-Path $env:TEMP $asset.name
Say "下载 $($asset.name) ($([math]::Round($asset.size/1MB,1)) MB) ..."
Invoke-WebRequest $asset.browser_download_url -OutFile $zipPath -UseBasicParsing

$sums = $rel.assets | Where-Object { $_.name -eq "SHA256SUMS" } | Select-Object -First 1
if ($sums) {
  $sumText = (Invoke-WebRequest $sums.browser_download_url -UseBasicParsing).Content
  $want = ($sumText -split "`n" | Where-Object { $_ -match [regex]::Escape($asset.name) }) -split '\s+' | Select-Object -First 1
  $got = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower()
  if ($want -and $got -ne $want.ToLower()) { Die "SHA256 校验失败：期望 $want，实际 $got" }
  Say "SHA256 校验通过"
}

Expand-Archive $zipPath -DestinationPath $Dir -Force
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

if (-not $PgPassword) {
  $sec = Read-Host "请输入 PostgreSQL 密码（用户 $PgUser@${PgHost}:$PgPort）" -AsSecureString
  $PgPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}

$cfg = [ordered]@{
  database  = [ordered]@{ host = $PgHost; port = $PgPort; user = $PgUser; password = $PgPassword; dbname = $PgDb; sslmode = "disable" }
  skill_dir = (Join-Path $Dir "skills")
}
$cfg | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $Dir "config.json") -Encoding utf8
Say "已写入 config.json"

Say "启动服务 ..."
Start-Process -FilePath (Join-Path $Dir "start.bat") -WorkingDirectory $Dir -WindowStyle Hidden
Start-Sleep -Seconds 6

Write-Host ""
Write-Host "  Lucky 已启动" -ForegroundColor Green
Write-Host "  控制台：  http://127.0.0.1:$Port"
Write-Host "  初始化：  http://127.0.0.1:$Port/setup"
Write-Host "  数据目录：$Dir"