# 把本地 Lucky 仓库推到 GitHub，并触发一键部署所需的 Release
#
# 用法：
#   .\tools\push-to-github.ps1 -Repo "你的账号/lucky" -Token "ghp_xxx"
#
# Token 权限（二选一）：
#   · Classic token：勾 repo + workflow
#   · Fine-grained：Repository permissions → Contents: Read/Write、Workflows: Read/Write
#     （若仓库还不存在，另需在账号级开启 "Administration" 或先手动建空仓库）

param(
  [Parameter(Mandatory = $true)][string]$Repo,      # owner/name
  [Parameter(Mandatory = $true)][string]$Token,
  [string]$Version = "1.0.0",
  [string]$Message = "chore: release v$Version",
  [switch]$SkipCreate,
  [switch]$SkipTag
)

$ErrorActionPreference = "Stop"
$tc = "C:\Users\111111\Desktop\999\toolchain"
$git = Join-Path $tc "git\cmd\git.exe"
$root = Split-Path $PSScriptRoot -Parent
$env:GIT_CONFIG_GLOBAL = Join-Path $tc "home\.gitconfig"

function Say($m) { Write-Host "[push] $m" -ForegroundColor Cyan }
function Die($m) { Write-Host "[push] $m" -ForegroundColor Red; exit 1 }

if ($Repo -notmatch '^[^/]+/[^/]+$') { Die "Repo 需为 owner/name 形式" }
$owner, $name = $Repo.Split('/')

function Api($method, $path, $body) {
  $headers = @{
    Authorization          = "Bearer $Token"
    Accept                 = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent"           = "lucky-deploy"
  }
  $args = @{ Method = $method; Uri = "https://api.github.com$path"; Headers = $headers }
  if ($body) { $args.Body = ($body | ConvertTo-Json -Depth 5); $args.ContentType = "application/json" }
  try { return Invoke-RestMethod @args }
  catch {
    $code = $_.Exception.Response.StatusCode.value__
    return @{ __error = $code; __message = $_.ErrorDetails.Message }
  }
}

# ---- 1) 校验 token ----
$me = Api GET "/user"
if ($me.__error) { Die "Token 无效或已过期（HTTP $($me.__error)）" }
Say "登录身份：$($me.login)"
if ($me.login -ne $owner) { Write-Warning "Token 属于 $($me.login)，仓库 owner 是 $owner（组织仓库可忽略）" }

# ---- 2) 建仓库（不存在时） ----
if (-not $SkipCreate) {
  $existing = Api GET "/repos/$Repo"
  if ($existing.__error -eq 404) {
    Say "仓库不存在，创建 $Repo ..."
    $created = Api POST "/user/repos" @{
      name        = $name
      private     = $false
      description = "Lucky — any 出品的 LLM 多智能体自主安全测试平台"
      has_issues  = $true
      has_wiki    = $false
    }
    if ($created.__error) { Die "创建仓库失败：$($created.__message)" }
    Say "已创建：$($created.html_url)"
  } elseif ($existing.__error) {
    Die "读取仓库失败：$($existing.__message)"
  } else {
    Say "仓库已存在：$($existing.html_url)"
  }
}

# ---- 3) 把占位符换成真实仓库 slug 并提交 ----
Push-Location $root
$utf8 = New-Object System.Text.UTF8Encoding $false
$changed = @()
foreach ($rel in @("install.sh", "install.ps1", "README.md")) {
  $p = Join-Path $root $rel
  if (-not (Test-Path $p)) { continue }
  $t = [IO.File]::ReadAllText($p)
  if ($t -match '__GH_REPO__') {
    [IO.File]::WriteAllText($p, ($t -replace '__GH_REPO__', $Repo), $utf8)
    $changed += $rel
  }
}
if ($changed.Count -gt 0) {
  Say "写入仓库地址到：$($changed -join ', ')"
  & $git add install.sh install.ps1 README.md 2>$null
  & $git -c user.name="Lucky Maintainer" -c user.email="maintainer@any.local" commit -m "chore: 指向仓库 $Repo（安装脚本与文档）" | Out-Null
}

# ---- 4) 推送 ----
try {
  $remote = "https://x-access-token:$Token@github.com/$Repo.git"
  & $git remote remove origin 2>$null
  & $git remote add origin $remote
  Say "推送 main ..."
  & $git push -u origin main
  if ($LASTEXITCODE -ne 0) { Die "推送失败" }

  if (-not $SkipTag) {
    $tag = "v$Version"
    & $git tag -f $tag -m "Lucky $tag"
    Say "推送 tag $tag（触发 Actions 构建多平台产物 + GHCR 镜像）..."
    & $git push -f origin $tag
  }

  # 远端 URL 里不要留 token
  & $git remote set-url origin "https://github.com/$Repo.git"
} finally {
  Pop-Location
}

Write-Host ""
Say "完成。"
Write-Host "  仓库：   https://github.com/$Repo"
Write-Host "  Actions：https://github.com/$Repo/actions"
Write-Host "  Release：https://github.com/$Repo/releases"
Write-Host ""
Write-Host "  一键部署（发布完成后可用）：" -ForegroundColor Green
Write-Host "    curl -fsSL https://raw.githubusercontent.com/$Repo/main/install.sh | sh"
Write-Host "    irm https://raw.githubusercontent.com/$Repo/main/install.ps1 | iex"
