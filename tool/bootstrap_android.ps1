# 本地补齐 Android 平台工程（gradle wrapper、启动主题、应用图标等）
#
# 仓库里只提交了业务相关的 Android 文件（权限清单 + MainActivity），
# 其余平台文件由 `flutter create` 生成后按「不覆盖已有文件」的方式补齐。
#
# 用法： powershell -ExecutionPolicy Bypass -File tool\bootstrap_android.ps1
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw '未找到 flutter，请先安装 Flutter SDK 并加入 PATH'
}

function Copy-Missing([string]$src, [string]$dst) {
  if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }
  Get-ChildItem -LiteralPath $src -Recurse -Force | ForEach-Object {
    $relative = $_.FullName.Substring($src.Length).TrimStart('\', '/')
    $target = Join-Path $dst $relative
    if ($_.PSIsContainer) {
      if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
    } elseif (-not (Test-Path $target)) {
      Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    }
  }
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('pg_scaffold_' + [guid]::NewGuid().ToString('N'))
flutter create --platforms=android --org com.example --project-name personal_growth $tmp
if ($LASTEXITCODE -ne 0) { throw 'flutter create 执行失败' }

Copy-Missing (Join-Path $tmp 'android') (Join-Path $root 'android')
Remove-Item -Recurse -Force $tmp

flutter pub get
Write-Host 'Android 平台工程已补齐，接下来可执行： flutter build apk --debug'
