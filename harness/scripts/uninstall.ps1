#requires -Version 5.1
<#
.SYNOPSIS
  Удаление глобальной установки harness для текущего пользователя.

.DESCRIPTION
  Делает backup и удаляет только глобальные harness-файлы:
  агентов harness-*, команды harness-*, skill harness и каталог harness.
  Проектные harness/ и docs/ не затрагиваются.
  Правила permission.task в opencode.jsonc нужно удалить вручную (скрипт печатает напоминание).
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

if (-not $Force) {
    $answer = Read-Host "Удалить глобальную установку harness? Проектные файлы не затрагиваются. [y/N]"
    if ($answer -notmatch '^(y|yes|д|да)$') {
        Write-Host "Отменено."
        exit 0
    }
}

$UserProfile = [Environment]::GetFolderPath("UserProfile")
Set-Location $UserProfile
$GlobalRoot = Join-Path $UserProfile ".config\opencode"
$GlobalHarness = Join-Path $GlobalRoot "harness"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = Join-Path $GlobalRoot "backups\harness-uninstall-$Timestamp"

New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null

$targets = @()
$targets += Get-ChildItem -LiteralPath (Join-Path $GlobalRoot "agents") -Filter "harness*.md" -File -ErrorAction SilentlyContinue
$targets += Get-ChildItem -LiteralPath (Join-Path $GlobalRoot "commands") -Filter "harness-*.md" -File -ErrorAction SilentlyContinue

foreach ($target in $targets) {
    Copy-Item -LiteralPath $target.FullName -Destination (Join-Path $BackupRoot $target.Name) -Force
    Remove-Item -LiteralPath $target.FullName -Force
    Write-Host "Удалён $($target.FullName)"
}

$skillPath = Join-Path $GlobalRoot "skills\harness"
if (Test-Path -LiteralPath $skillPath) {
    Copy-Item -LiteralPath $skillPath -Destination (Join-Path $BackupRoot "skills-harness") -Recurse -Force
    Remove-Item -LiteralPath $skillPath -Recurse -Force
    Write-Host "Удалён $skillPath"
}

if (Test-Path -LiteralPath $GlobalHarness) {
    Copy-Item -LiteralPath $GlobalHarness -Destination (Join-Path $BackupRoot "harness") -Recurse -Force
    Remove-Item -LiteralPath $GlobalHarness -Recurse -Force
    Write-Host "Удалён $GlobalHarness"
}

Write-Host ""
Write-Host "Backup: $BackupRoot"
Write-Host "Проектные harness/ и docs/ не изменялись."
Write-Host ""
Write-Host "Не забудьте удалить из ~/.config/opencode/opencode.jsonc блок permission.task:"
Write-Host '  "task": {'
Write-Host '    "harness-orchestrator": "deny",'
Write-Host '    "harness-analyst": "deny",'
Write-Host '    "harness-architect": "deny",'
Write-Host '    "harness-coder": "deny",'
Write-Host '    "harness-qa": "deny",'
Write-Host '    "harness-doc-writer": "deny"'
Write-Host '  }'
