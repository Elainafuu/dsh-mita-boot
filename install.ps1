param(
  [string]$Profile = "desktop",
  [string]$DshHome = "$env:USERPROFILE\.dsh",
  [switch]$SkipPatches
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$tplName = "deepseek-game-boot"
$tplDst = Join-Path $DshHome "startup-templates\$tplName"
$patchFile = Join-Path $root "patches\mizhu-live-boot.patch"

Write-Host "== DSH 米塔式启动动画 安装 ==" -ForegroundColor Cyan
Write-Host "DSH_HOME: $DshHome"

if (-not (Test-Path $DshHome)) { throw "找不到 DSH_HOME：$DshHome（先运行一次 DSH）" }

# 1) 模板
if (Test-Path $tplDst) {
  $bak = "$tplDst.bak-" + (Get-Date -Format "yyyyMMdd-HHmmss")
  Move-Item $tplDst $bak
  Write-Host "旧模板已备份：$bak"
}
New-Item -ItemType Directory -Force $tplDst | Out-Null
Copy-Item (Join-Path $root "template\*") $tplDst -Recurse -Force
Write-Host "模板已安装：$tplDst" -ForegroundColor Green

# 2) 配置
$cfgPath = Join-Path $DshHome "dsh-startup.json"
$cfg = @{}
if (Test-Path $cfgPath) {
  try { $cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable } catch { $cfg = @{} }
}
$cfg["template"] = $tplName
$cfg["act2"] = ""
$cfg["transitionOut"] = "none"
$json = $cfg | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($cfgPath, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "配置已写入：$cfgPath" -ForegroundColor Green

# 3) 补丁
if ($SkipPatches) {
  Write-Host "已跳过补丁（-SkipPatches）"
  exit 0
}

$plugin = Join-Path $DshHome "profiles\$Profile\node_modules\dsh-boot-suite"
if (-not (Test-Path $plugin)) {
  Write-Warning "没找到 dsh-boot-suite：$plugin"
  Write-Warning "模板已经装好，但没有补丁时片尾交接会退回插件默认行为（会有定格/黑幕）。"
  exit 0
}

$gitExe = $null
$g = Get-Command git -ErrorAction SilentlyContinue
if ($g) { $gitExe = $g.Source } elseif (Test-Path "C:\Program Files\Git\cmd\git.exe") { $gitExe = "C:\Program Files\Git\cmd\git.exe" }
if (-not $gitExe) { throw "需要 git 来打补丁：winget install Git.Git" }

if (-not (Test-Path $patchFile)) { throw "缺少补丁文件：$patchFile" }

# 备份三个会改到的文件
foreach ($f in "splash.js", "splash.css", "host-startup.js") {
  $p = Join-Path $plugin "lib\$f"
  if ((Test-Path $p) -and -not (Test-Path "$p.bak-mita")) {
    Copy-Item $p "$p.bak-mita" -Force
    Write-Host "已备份：lib\$f.bak-mita"
  }
}

Push-Location $plugin
try {
  & $gitExe apply -p1 --whitespace=nowarn $patchFile 2>&1 | Out-Host
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "补丁没有完全应用：可能 dsh-boot-suite 不是 2.13.x，或已经打过。"
    Write-Warning "可以用 lib\*.bak-mita 还原后再试。"
  } else {
    Write-Host "补丁已应用" -ForegroundColor Green
  }
} finally { Pop-Location }

Write-Host ""
Write-Host "完成。重启 DeepSeek Harness 即可看到新的启动动画。" -ForegroundColor Cyan
