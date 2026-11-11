#requires -Version 5.1
<#
.SYNOPSIS
  Remove the global harness installation for the current user.

.DESCRIPTION
  Backs up and removes only global harness files:
  harness-* agents, harness-* commands, harness skills, and the harness directory.
  Project harness/ and docs/ are not touched.
  permission.task rules in opencode.jsonc must be removed manually (the script prints a reminder).
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

if (-not $Force) {
    $answer = Read-Host "Remove the global harness installation? Project files are not touched. [y/N]"
    if ($answer -notmatch '^(y|yes)$') {
        Write-Host "Cancelled."
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
    Write-Host "Removed $($target.FullName)"
}

$skillsRoot = Join-Path $GlobalRoot "skills"
if (Test-Path -LiteralPath $skillsRoot) {
    New-Item -ItemType Directory -Force -Path (Join-Path $BackupRoot "skills") | Out-Null
    Get-ChildItem -LiteralPath $skillsRoot -Directory -Filter "harness*" -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $BackupRoot "skills") -Recurse -Force
        Remove-Item -LiteralPath $_.FullName -Recurse -Force
        Write-Host "Removed $($_.FullName)"
    }
}

if (Test-Path -LiteralPath $GlobalHarness) {
    Copy-Item -LiteralPath $GlobalHarness -Destination (Join-Path $BackupRoot "harness") -Recurse -Force
    Remove-Item -LiteralPath $GlobalHarness -Recurse -Force
    Write-Host "Removed $GlobalHarness"
}

Write-Host ""
Write-Host "Backup: $BackupRoot"
Write-Host "Project harness/ and docs/ were not modified."
Write-Host ""
Write-Host "Do not forget to remove the permission.task block from ~/.config/opencode/opencode.jsonc:"
Write-Host '  "task": {'
Write-Host '    "harness-orchestrator": "deny",'
Write-Host '    "harness-analyst": "deny",'
Write-Host '    "harness-ux-designer": "deny",'
Write-Host '    "harness-architect": "deny",'
Write-Host '    "harness-coder": "deny",'
Write-Host '    "harness-qa": "deny",'
Write-Host '    "harness-qa-vision": "deny",'
Write-Host '    "harness-doc-writer": "deny"'
Write-Host '  }'
