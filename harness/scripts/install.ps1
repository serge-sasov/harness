#requires -Version 5.1
<#
.SYNOPSIS
  Global installation of the local harness for the current user.

.DESCRIPTION
  Copies agents, commands, skill, workflows, and templates to ~/.config/opencode,
  backs up changed files, and adds or repairs permission rules for harness agents
  plus the top-level subagent_depth for self-sub-sessions in opencode.jsonc
  (if the file has no comments).

.PARAMETER SkipConfig
  Do not modify opencode.jsonc; only print the ready JSON snippet.
#>
[CmdletBinding()]
param(
    [switch]$SkipConfig,
    [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Text
    )
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

function Backup-IfExists {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$BackupRoot
    )
    if (Test-Path -LiteralPath $Path) {
        New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
        $name = Split-Path -Leaf $Path
        $destination = Join-Path $BackupRoot $name
        Copy-Item -LiteralPath $Path -Destination $destination -Recurse -Force
    }
}

function Get-BraceBlock {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][int]$OpenIndex
    )
    $depth = 0
    $inString = $false
    $escape = $false
    for ($i = $OpenIndex; $i -lt $Text.Length; $i++) {
        $ch = $Text[$i]
        if ($inString) {
            if ($escape) { $escape = $false }
            elseif ($ch -eq '\') { $escape = $true }
            elseif ($ch -eq '"') { $inString = $false }
            continue
        }
        if ($ch -eq '"') { $inString = $true }
        elseif ($ch -eq '{') { $depth++ }
        elseif ($ch -eq '}') {
            $depth--
            if ($depth -eq 0) {
                return [pscustomobject]@{
                    Start = $OpenIndex
                    End   = $i
                    Text  = $Text.Substring($OpenIndex, $i - $OpenIndex + 1)
                }
            }
        }
    }
    return $null
}

function Add-MissingTaskAllows {
    param(
        [Parameter(Mandatory = $true)][string]$Raw,
        [Parameter(Mandatory = $true)][string[]]$Ids
    )
    $taskMatch = [regex]::Match($Raw, '"task"\s*:\s*\{')
    if (-not $taskMatch.Success) { return $null }
    $openIndex = $Raw.IndexOf('{', $taskMatch.Index)
    if ($openIndex -lt 0) { return $null }
    $block = Get-BraceBlock -Text $Raw -OpenIndex $openIndex
    if ($null -eq $block) { return $null }

    $missing = @($Ids | Where-Object {
        $block.Text -notmatch ('"' + [regex]::Escape($_) + '"\s*:\s*"(?:allow|deny|ask)"')
    })
    if ($missing.Count -eq 0) { return $Raw }

    $inner = $Raw.Substring($block.Start + 1, $block.End - $block.Start - 1)
    $indent = "      "
    $indentMatch = [regex]::Match($inner, '(?m)^([ \t]+)"[^"]+"\s*:')
    if ($indentMatch.Success) { $indent = $indentMatch.Groups[1].Value }

    $before = $inner.TrimEnd()
    if ($before.Length -gt 0 -and -not $before.EndsWith(',')) { $before += ',' }
    $entryLines = @()
    for ($i = 0; $i -lt $missing.Count; $i++) {
        $comma = if ($i -lt ($missing.Count - 1)) { "," } else { "" }
        $entryLines += "$indent`"$($missing[$i])`": `"allow`"$comma"
    }
    $entryText = $entryLines -join "`r`n"
    if ($before.Length -gt 0) {
        $newInner = $before + "`r`n" + $entryText + "`r`n    "
    }
    else {
        $newInner = "`r`n" + $entryText + "`r`n    "
    }
    return $Raw.Substring(0, $block.Start + 1) + $newInner + $Raw.Substring($block.End)
}

function Set-SubagentDepth {
    param(
        [Parameter(Mandatory = $true)][string]$Raw,
        [int]$Minimum = 2
    )
    $match = [regex]::Match($Raw, '"subagent_depth"\s*:\s*(\d+)')
    if ($match.Success) {
        $current = [int]$match.Groups[1].Value
        if ($current -ge $Minimum) { return $Raw }
        return [regex]::Replace($Raw, '("subagent_depth"\s*:\s*)\d+', ('${1}' + $Minimum), 'None')
    }
    $top = [regex]::Match($Raw, '^\s*\{')
    if (-not $top.Success) { return $Raw }
    $insertAt = $top.Index + $top.Length
    $entry = "`r`n  `"subagent_depth`": $Minimum,"
    return $Raw.Substring(0, $insertAt) + $entry + $Raw.Substring($insertAt)
}

$SourceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$UserProfile = [Environment]::GetFolderPath("UserProfile")
$GlobalRoot = Join-Path $UserProfile ".config\opencode"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = Join-Path $GlobalRoot "backups\harness-install-$Timestamp"

$requiredSource = @(
    (Join-Path $SourceRoot "agents\harness.md"),
    (Join-Path $SourceRoot "agents\harness-orchestrator.md"),
    (Join-Path $SourceRoot "agents\harness-ux-designer.md"),
    (Join-Path $SourceRoot "agents\harness-qa-vision.md"),
    (Join-Path $SourceRoot "commands\harness-run.md"),
    (Join-Path $SourceRoot "commands\harness-feature.md"),
    (Join-Path $SourceRoot "commands\harness-bug.md"),
    (Join-Path $SourceRoot "skills\harness\SKILL.md"),
    (Join-Path $SourceRoot "skills\harness-issues\SKILL.md"),
    (Join-Path $SourceRoot "workflows\feature.md"),
    (Join-Path $SourceRoot "workflows\bugfix.md"),
    (Join-Path $SourceRoot "templates\issue.md"),
    (Join-Path $SourceRoot "templates\checkpoint.md"),
    (Join-Path $SourceRoot "templates\task-card.md"),
    (Join-Path $SourceRoot "templates\task-card-feature.md"),
    (Join-Path $SourceRoot "templates\task-card-bugfix.md"),
    (Join-Path $SourceRoot "templates\bug-card.md"),
    (Join-Path $SourceRoot "templates\e2e-use-case.md"),
    (Join-Path $SourceRoot "templates\e2e-test-data.yaml"),
    (Join-Path $SourceRoot "templates\ux-spec.md"),
    (Join-Path $SourceRoot "scripts\new-issue.ps1"),
    (Join-Path $SourceRoot "scripts\check-budget.ps1"),
    (Join-Path $SourceRoot "scripts\validate-e2e-data.py"),
    (Join-Path $SourceRoot "process.md"),
    (Join-Path $SourceRoot "version.json")
)
foreach ($item in $requiredSource) {
    if (-not (Test-Path -LiteralPath $item)) {
        throw "Required harness file not found: $item"
    }
}

$sourceSkills = @(Get-ChildItem -LiteralPath (Join-Path $SourceRoot "skills") -Directory)
if ($sourceSkills.Count -eq 0) {
    throw "No skills found in $SourceRoot\skills."
}

New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $GlobalRoot "agents") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $GlobalRoot "commands") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $GlobalRoot "skills") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $GlobalRoot "harness") | Out-Null

# Backup existing global harness files
foreach ($pattern in @("harness*.md")) {
    Get-ChildItem -LiteralPath (Join-Path $GlobalRoot "agents") -Filter $pattern -File -ErrorAction SilentlyContinue |
        ForEach-Object { Backup-IfExists -Path $_.FullName -BackupRoot (Join-Path $BackupRoot "agents") }
}
foreach ($pattern in @("harness-*.md")) {
    Get-ChildItem -LiteralPath (Join-Path $GlobalRoot "commands") -Filter $pattern -File -ErrorAction SilentlyContinue |
        ForEach-Object { Backup-IfExists -Path $_.FullName -BackupRoot (Join-Path $BackupRoot "commands") }
}
if (Test-Path -LiteralPath (Join-Path $GlobalRoot "skills")) {
    foreach ($skill in $sourceSkills) {
        $targetSkill = Join-Path (Join-Path $GlobalRoot "skills") $skill.Name
        if (Test-Path -LiteralPath $targetSkill) {
            Backup-IfExists -Path $targetSkill -BackupRoot (Join-Path $BackupRoot "skills")
        }
    }
}
if (Test-Path -LiteralPath (Join-Path $GlobalRoot "harness")) {
    Backup-IfExists -Path (Join-Path $GlobalRoot "harness") -BackupRoot (Join-Path $BackupRoot "harness")
}
if (Test-Path -LiteralPath (Join-Path $GlobalRoot "opencode.jsonc")) {
    Copy-Item -LiteralPath (Join-Path $GlobalRoot "opencode.jsonc") -Destination (Join-Path $BackupRoot "opencode.jsonc") -Force
}

# Copy agents, commands, skills, and shared files
Copy-Item -Path (Join-Path $SourceRoot "agents\*.md") -Destination (Join-Path $GlobalRoot "agents") -Force
Copy-Item -Path (Join-Path $SourceRoot "commands\*.md") -Destination (Join-Path $GlobalRoot "commands") -Force
foreach ($skill in $sourceSkills) {
    Copy-Item -Path $skill.FullName -Destination (Join-Path $GlobalRoot "skills") -Recurse -Force
}

$globalHarness = Join-Path $GlobalRoot "harness"
Copy-Item -Path (Join-Path $SourceRoot "process.md") -Destination $globalHarness -Force
Copy-Item -Path (Join-Path $SourceRoot "version.json") -Destination $globalHarness -Force
Copy-Item -Path (Join-Path $SourceRoot "templates") -Destination $globalHarness -Recurse -Force
Copy-Item -Path (Join-Path $SourceRoot "workflows") -Destination $globalHarness -Recurse -Force
Copy-Item -Path (Join-Path $SourceRoot "scripts") -Destination $globalHarness -Recurse -Force

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $configPath = Join-Path $GlobalRoot "opencode.jsonc"
}
else {
    $configPath = $ConfigPath
}
$harnessIds = @(
    "harness-orchestrator",
    "harness-analyst",
    "harness-ux-designer",
    "harness-architect",
    "harness-coder",
    "harness-qa",
    "harness-qa-vision",
    "harness-doc-writer"
)

if (-not $SkipConfig) {
    if (-not (Test-Path -LiteralPath $configPath)) {
        $lines = @(
            "{",
            '  "$schema": "https://opencode.ai/config.json",',
            '  "subagent_depth": 2,',
            '  "permission": {',
            '    "task": {'
        )
        for ($i = 0; $i -lt $harnessIds.Count; $i++) {
            $comma = if ($i -lt ($harnessIds.Count - 1)) { "," } else { "" }
            $lines += "      `"$($harnessIds[$i])`": `"allow`"$comma"
        }
        $lines += @("    }", "  }", "}")
        Write-Utf8NoBom -Path $configPath -Text (($lines -join "`r`n") + "`r`n")
        Write-Host "Created $configPath with harness allow rules."
    }
    else {
        $raw = Get-Content -LiteralPath $configPath -Raw
        $configBackup = Join-Path $BackupRoot "opencode.jsonc"
        if ($configPath -ne (Join-Path $GlobalRoot "opencode.jsonc")) {
            $configBackup = Join-Path $BackupRoot "opencode-custom.jsonc"
            Copy-Item -LiteralPath $configPath -Destination $configBackup -Force
        }
        if ($raw -match '(?m)^\s*//' -or $raw -match '(?m)^\s*/\*') {
            Write-Warning "opencode.jsonc contains comments; automatic edit skipped."
            Write-Host "Add manually to the `"permission`" object:"
            Write-Host '  "task": {'
            foreach ($id in $harnessIds) {
                Write-Host "    `"$id`": `"allow`","
            }
            Write-Host '  }'
        }
        elseif ($raw -match '"task"\s*:') {
            $newRaw = $raw
            $changed = $false
            foreach ($id in $harnessIds) {
                $pattern = '("' + [regex]::Escape($id) + '"\s*:\s*)"(?:deny|allow|ask)"'
                if ($newRaw -match $pattern) {
                    $updated = [regex]::Replace($newRaw, $pattern, '$1"allow"')
                    if ($updated -ne $newRaw) {
                        $changed = $true
                        $newRaw = $updated
                    }
                }
            }
            $withMissing = Add-MissingTaskAllows -Raw $newRaw -Ids $harnessIds
            if ($null -eq $withMissing) {
                $missing = @($harnessIds | Where-Object {
                    $newRaw -notmatch ('"' + [regex]::Escape($_) + '"\s*:\s*"allow"')
                })
                Write-Warning "Cannot locate the permission.task block; add missing allow rules manually: $($missing -join ', ')"
            }
            elseif ($withMissing -ne $newRaw) {
                $newRaw = $withMissing
                $changed = $true
            }

            if ($changed) {
                Write-Utf8NoBom -Path $configPath -Text $newRaw
                try {
                    Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json | Out-Null
                    Write-Host "permission.task: harness roles set to allow (missing entries added)."
                }
                catch {
                    Copy-Item -LiteralPath $configBackup -Destination $configPath -Force
                    throw "opencode.jsonc validation failed; file restored from backup. $_"
                }
            }
            else {
                $missing = @($harnessIds | Where-Object {
                    $newRaw -notmatch ('"' + [regex]::Escape($_) + '"\s*:\s*"allow"')
                })
                if ($missing.Count -eq 0) {
                    Write-Host "permission.task already allows all harness roles."
                }
                else {
                    Write-Warning "Missing allow rules in permission.task: $($missing -join ', ')"
                    Write-Host "Add manually:"
                    foreach ($id in $missing) {
                        Write-Host "  `"$id`": `"allow`""
                    }
                }
            }
        }
        else {
            $match = [regex]::Match($raw, '("permission"\s*:\s*\{)')
            if (-not $match.Success) {
                Write-Warning "No permission object found in opencode.jsonc; add rules manually."
            }
            else {
                $permOpen = $raw.IndexOf('{', $match.Index)
                $permBlock = if ($permOpen -ge 0) { Get-BraceBlock -Text $raw -OpenIndex $permOpen } else { $null }
                $permInner = if ($permBlock) { $raw.Substring($permBlock.Start + 1, $permBlock.End - $permBlock.Start - 1) } else { "" }
                $taskComma = if ($permInner.Trim().Length -gt 0) { "," } else { "" }
                $lines = @('    "task": {')
                for ($i = 0; $i -lt $harnessIds.Count; $i++) {
                    $comma = if ($i -lt ($harnessIds.Count - 1)) { "," } else { "" }
                    $lines += "      `"$($harnessIds[$i])`": `"allow`"$comma"
                }
                $lines += "    }$taskComma"
                $insert = ($lines -join "`r`n") + "`r`n"
                $newRaw = $raw.Substring(0, $match.Index + $match.Length) + "`r`n" + $insert + $raw.Substring($match.Index + $match.Length)
                Write-Utf8NoBom -Path $configPath -Text $newRaw
                try {
                    Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json | Out-Null
                    Write-Host "Added harness allow rules to opencode.jsonc."
                }
                catch {
                    Copy-Item -LiteralPath $configBackup -Destination $configPath -Force
                    throw "opencode.jsonc validation failed; file restored from backup. $_"
                }
            }
        }
    }

    if (Test-Path -LiteralPath $configPath) {
        $depthRaw = Get-Content -LiteralPath $configPath -Raw
        if ($depthRaw -match '(?m)^\s*//' -or $depthRaw -match '(?m)^\s*/\*') {
            Write-Warning "opencode.jsonc contains comments; set top-level `"subagent_depth`": 2 manually."
        }
        else {
            $depthNew = Set-SubagentDepth -Raw $depthRaw -Minimum 2
            if ($depthNew -ne $depthRaw) {
                $depthBackup = Join-Path $BackupRoot "opencode.jsonc.before-depth"
                Copy-Item -LiteralPath $configPath -Destination $depthBackup -Force
                Write-Utf8NoBom -Path $configPath -Text $depthNew
                try {
                    Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json | Out-Null
                    Write-Host "subagent_depth set to 2 (self-sub-sessions enabled)."
                }
                catch {
                    Copy-Item -LiteralPath $depthBackup -Destination $configPath -Force
                    throw "opencode.jsonc validation failed after subagent_depth update; file restored. $_"
                }
            }
            else {
                Write-Host "subagent_depth already >= 2."
            }
        }
    }
}
else {
    Write-Host "SkipConfig: add manually to the config:"
    Write-Host '  "subagent_depth": 2,'
    Write-Host "and to the permission object:"
    Write-Host '  "task": {'
    foreach ($id in $harnessIds) {
        Write-Host "    `"$id`": `"allow`","
    }
    Write-Host '  }'
}

Write-Host ""
Write-Host "Harness installed globally for user $UserProfile"
Write-Host "  agents:   $(Join-Path $GlobalRoot 'agents')"
Write-Host "  commands: $(Join-Path $GlobalRoot 'commands')"
Write-Host "  skills:   $($sourceSkills.Name -join ', ')"
Write-Host "  support:  $globalHarness"
Write-Host "  backup:   $BackupRoot"
Write-Host ""
Write-Host "Restart opencode, then run /harness-init in the project."
