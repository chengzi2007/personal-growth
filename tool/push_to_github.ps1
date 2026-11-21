# 用 GitHub REST API（Git Data API）把一个本地目录作为「单次提交」推送到新仓库。
# 无需安装 git，仅依赖 Windows 自带的 curl.exe。
#
# 用法（推荐：token 只放环境变量，避免出现在命令行/进程列表里）：
#   $env:GH_TOKEN = 'ghp_xxx'
#   powershell -ExecutionPolicy Bypass -File tool\push_to_github.ps1 -RepoName personal-growth -Visibility public
#
# 若不设环境变量也不传 -Token，脚本会以隐藏输入方式提示你粘贴 token。
#
# Token 权限：classic token 勾选 repo + workflow（workflow 用于提交 .github/workflows 文件）。
param(
  [string]$Token = $env:GH_TOKEN,
  [string]$RepoName = 'personal-growth',
  [ValidateSet('public', 'private')][string]$Visibility = 'public',
  [string]$CommitMessage = 'feat: 个人成长分析 Flutter App（首页/记录/分析/简历 + 本地打分）'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$api = 'https://api.github.com'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 没有可用 token 时改为隐藏输入，避免 token 被写进命令行历史
if ([string]::IsNullOrWhiteSpace($Token)) {
  $secure = Read-Host '粘贴 GitHub Token（输入不回显）' -AsSecureString
  $Token = [System.Net.NetworkCredential]::new('', $secure).Password
}
if ([string]::IsNullOrWhiteSpace($Token)) { throw '缺少 GitHub Token' }

function Gh([string]$method, [string]$url, $body) {
  $argv = @(
    '-sS', '-X', $method, $url,
    '-H', "Authorization: Bearer $Token",
    '-H', 'Accept: application/vnd.github+json',
    '-H', 'X-GitHub-Api-Version: 2022-11-28',
    '-H', 'User-Agent: trae-agent'
  )
  $tmp = $null
  if ($null -ne $body) {
    $tmp = Join-Path $env:TEMP ('gh_' + [guid]::NewGuid().ToString('N') + '.json')
    [System.IO.File]::WriteAllText($tmp, ($body | ConvertTo-Json -Depth 10 -Compress), $utf8NoBom)
    $argv += @('-H', 'Content-Type: application/json', '--data-binary', "@$tmp")
  }
  try {
    $raw = (& curl.exe @argv | Out-String).Trim()
  } finally {
    if ($tmp -and (Test-Path $tmp)) { Remove-Item $tmp -Force }
  }
  if ($LASTEXITCODE -ne 0) { throw "请求失败：$method $url" }
  if ([string]::IsNullOrWhiteSpace($raw)) { throw "空响应：$method $url" }
  return $raw
}

Write-Host '1/4 校验 token…'
$user = Gh 'GET' "$api/user" $null | ConvertFrom-Json
if (-not $user.login) { throw 'token 无效或缺少用户信息' }
$repoUrl = "$api/repos/$($user.login)/$RepoName"
Write-Host "    当前账号：$($user.login)"

$isEmpty = $false
$status = (& curl.exe -s -o NUL -w '%{http_code}' -H "Authorization: Bearer $Token" $repoUrl).Trim()
if ($status -eq '200') {
  $probe = Gh 'GET' "$repoUrl/git/refs/heads" $null
  if ($probe -notmatch '"ref"') {
    Write-Host '2/4 仓库已存在且为空，继续使用'
    $isEmpty = $true
  } else {
    throw "仓库 $($user.login)/$RepoName 已存在且非空，请换一个仓库名或先删除它"
  }
} elseif ($status -eq '404') {
  Write-Host '2/4 创建仓库…'
  $created = Gh 'POST' "$api/user/repos" @{
    name        = $RepoName
    private     = ($Visibility -ne 'public')
    auto_init   = $false
    has_issues  = $true
    description = '个人成长分析 · 纯本地 Flutter App'
  } | ConvertFrom-Json
  Write-Host "    已创建：$($created.html_url)"
  $isEmpty = $true
} else {
  throw "查询仓库失败，HTTP $status"
}

# 空仓库无法直接创建 blob（409 Git Repository is empty），先用 Contents API 落一个初始提交
$parents = @()
if ($isEmpty) {
  Write-Host '    初始化空仓库（建立首个分支）…'
  $seedContent = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("# $RepoName`n"))
  $seed = Gh 'PUT' "$repoUrl/contents/README.md" @{
    message = 'chore: 初始化仓库'
    content = $seedContent
  } | ConvertFrom-Json
  if (-not $seed.commit.sha) { throw '初始化仓库失败' }
  $parents = @($seed.commit.sha)
}
$branch = (Gh 'GET' $repoUrl $null | ConvertFrom-Json).default_branch
if ([string]::IsNullOrWhiteSpace($branch)) { $branch = 'main' }

Write-Host '3/4 上传文件（每个文件 -> blob）…'
$files = Get-ChildItem -LiteralPath $repoRoot -Recurse -File | Where-Object {
  $_.FullName -notmatch '\\(build|\.git|\.dart_tool|\.archify)\\' -and
  $_.Name -notlike '*.iml'
} | Sort-Object FullName

$tree = @()
foreach ($file in $files) {
  $rel = $file.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
  $blob = Gh 'POST' "$repoUrl/git/blobs" @{
    content  = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($file.FullName))
    encoding = 'base64'
  } | ConvertFrom-Json
  if (-not $blob.sha) { throw "上传失败：$rel" }
  $tree += @{ path = $rel; mode = '100644'; type = 'blob'; sha = $blob.sha }
  Write-Host "    + $rel"
}

Write-Host '4/4 创建提交并推送…'
$treeResp = Gh 'POST' "$repoUrl/git/trees" @{ tree = $tree } | ConvertFrom-Json
$commitBody = @{ message = $CommitMessage; tree = $treeResp.sha }
if ($parents.Count -gt 0) { $commitBody['parents'] = $parents }
$commit = Gh 'POST' "$repoUrl/git/commits" $commitBody | ConvertFrom-Json

if ($parents.Count -gt 0) {
  Gh 'PATCH' "$repoUrl/git/refs/heads/$branch" @{ sha = $commit.sha; force = $true } | Out-Null
} else {
  Gh 'POST' "$repoUrl/git/refs" @{ ref = "refs/heads/$branch"; sha = $commit.sha } | Out-Null
}
try { Gh 'PATCH' $repoUrl @{ default_branch = $branch } | Out-Null } catch { Write-Warning '默认分支设置失败（不影响构建）' }

Write-Host ''
Write-Host "完成：$($repoUrl -replace 'api\.github\.com/repos', 'github.com')"
Write-Host "提交：$($commit.sha.Substring(0, 7))"
Write-Host "Actions：https://github.com/$($user.login)/$RepoName/actions"
Write-Host "APK 构建完成后可在该次运行的 Artifacts 中下载；如需我代为下载，请告诉我。"
