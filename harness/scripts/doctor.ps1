#requires -Version 5.1
<#
.SYNOPSIS
  Check the global harness installation, model readiness, and the current project.

.DESCRIPTION
  Verifies global harness files, permission.path variants, permission.task,
  issue registry and index consistency, the compaction handoff plugin, model
  num_ctx against limit.context, and the local-rag MCP timeout.

.PARAMETER SkipModelProbe
  Skip the live `ollama show` comparison of configured and actual context sizes.
#>
[CmdletBinding()]
param(
    [switch]$SkipModelProbe
)

$ErrorActionPreference = "Stop"
$script:critical = $false

function Write-Ok($text) { Write-Host "[ok]   $text" -ForegroundColor Green }
function Write-Warn($text) { Write-Host "[warn] $text" -ForegroundColor Yellow }
function Write-Err($text) { Write-Host "[err]  $text" -ForegroundColor Red; $script:critical = $true }
function Write-Info($text) { Write-Host "[info] $text" -ForegroundColor Gray }

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
            if ($depth -eq 0) { return $Text.Substring($OpenIndex, $i - $OpenIndex + 1) }
        }
    }
    return $null
}

function Get-ConfiguredContextValues {
    param(
        [Parameter(Mandatory = $true)][string]$ConfigText,
        [Parameter(Mandatory = $true)][string]$Model
    )
    $values = @()
    $keyPattern = '"' + [regex]::Escape($Model) + '"\s*:\s*\{'
    foreach ($keyMatch in [regex]::Matches($ConfigText, $keyPattern)) {
        $openIndex = $ConfigText.IndexOf('{', $keyMatch.Index)
        if ($openIndex -lt 0) { continue }
        $modelBlock = Get-BraceBlock -Text $ConfigText -OpenIndex $openIndex
        if (-not $modelBlock) { continue }
        $limitMatch = [regex]::Match($modelBlock, '"limit"\s*:\s*\{')
        if (-not $limitMatch.Success) { continue }
        $limitOpen = $modelBlock.IndexOf('{', $limitMatch.Index)
        if ($limitOpen -lt 0) { continue }
        $limitBlock = Get-BraceBlock -Text $modelBlock -OpenIndex $limitOpen
        if (-not $limitBlock) { continue }
        $contextMatch = [regex]::Match($limitBlock, '"context"\s*:\s*(\d+)')
        if ($contextMatch.Success) { $values += [int]$contextMatch.Groups[1].Value }
    }
    return $values
}

function Get-OllamaNumCtx {
    param([Parameter(Mandatory = $true)][string]$Model)
    $output = @(& ollama show $Model 2>$null)
    if ($LASTEXITCODE -ne 0 -or $output.Count -eq 0) { return $null }
    $match = [regex]::Match(($output -join "`n"), '(?m)^\s*num_ctx\s+(\d+)\s*$')
    if ($match.Success) { return [int]$match.Groups[1].Value }
    return $null
}

$UserProfile = [Environment]::GetFolderPath("UserProfile")
$GlobalRoot = Join-Path $UserProfile ".config\opencode"
$GlobalHarness = Join-Path $GlobalRoot "harness"
$Project = (Get-Location).Path

Write-Host "Harness doctor"
Write-Host "  user:    $UserProfile"
Write-Host "  project: $Project"
Write-Host ""

$globalFiles = @(
    (Join-Path $GlobalRoot "agents\harness.md"),
    (Join-Path $GlobalRoot "agents\harness-orchestrator.md"),
    (Join-Path $GlobalRoot "agents\harness-analyst.md"),
    (Join-Path $GlobalRoot "agents\harness-ux-designer.md"),
    (Join-Path $GlobalRoot "agents\harness-architect.md"),
    (Join-Path $GlobalRoot "agents\harness-coder.md"),
    (Join-Path $GlobalRoot "agents\harness-qa.md"),
    (Join-Path $GlobalRoot "agents\harness-qa-vision.md"),
    (Join-Path $GlobalRoot "agents\harness-doc-writer.md"),
    (Join-Path $GlobalRoot "commands\harness-init.md"),
    (Join-Path $GlobalRoot "commands\harness-feature.md"),
    (Join-Path $GlobalRoot "commands\harness-bug.md"),
    (Join-Path $GlobalRoot "commands\harness-run.md"),
    (Join-Path $GlobalRoot "commands\harness-board-update.md"),
    (Join-Path $GlobalRoot "commands\harness-board-report.md"),
    (Join-Path $GlobalRoot "commands\harness-doctor.md"),
    (Join-Path $GlobalRoot "skills\harness\SKILL.md"),
    (Join-Path $GlobalRoot "skills\harness-issues\SKILL.md"),
    (Join-Path $GlobalHarness "process.md"),
    (Join-Path $GlobalHarness "version.json"),
    (Join-Path $GlobalHarness "workflows\feature.md"),
    (Join-Path $GlobalHarness "workflows\bugfix.md"),
    (Join-Path $GlobalHarness "templates\task-card.md"),
    (Join-Path $GlobalHarness "templates\task-card-feature.md"),
    (Join-Path $GlobalHarness "templates\task-card-bugfix.md"),
    (Join-Path $GlobalHarness "templates\bug-card.md"),
    (Join-Path $GlobalHarness "templates\adr.md"),
    (Join-Path $GlobalHarness "templates\plan-row.md"),
    (Join-Path $GlobalHarness "templates\issue.md"),
    (Join-Path $GlobalHarness "templates\checkpoint.md"),
    (Join-Path $GlobalHarness "templates\e2e-use-case.md"),
    (Join-Path $GlobalHarness "templates\e2e-test-data.yaml"),
    (Join-Path $GlobalHarness "templates\ux-spec.md"),
    (Join-Path $GlobalHarness "scripts\new-issue.ps1"),
    (Join-Path $GlobalHarness "scripts\check-budget.ps1"),
    (Join-Path $GlobalHarness "scripts\validate-e2e-data.py")
)
$missingGlobal = @()
foreach ($file in $globalFiles) {
    if (-not (Test-Path -LiteralPath $file)) { $missingGlobal += $file }
}
if ($missingGlobal.Count -eq 0) {
    Write-Ok "global agents, commands, skills, and templates are present"
}
else {
    Write-Err "missing global harness files:"
    $missingGlobal | ForEach-Object { Write-Host "       $_" }
}

$agentFiles = @(Get-ChildItem -LiteralPath (Join-Path $GlobalRoot "agents") -Filter "harness*.md" -File -ErrorAction SilentlyContinue)
$missingCounterparts = @()
foreach ($agentFile in $agentFiles) {
    $section = ""
    $sectionAllows = @{ "edit" = @(); "read" = @() }
    foreach ($line in (Get-Content -LiteralPath $agentFile.FullName)) {
        if ($line -match '^\s{2}([A-Za-z0-9_-]+):') {
            $section = $Matches[1]
            continue
        }
        if ($line -match '^[A-Za-z0-9_-]+:') { $section = ""; continue }
        if ($section -in @("edit", "read")) {
            $allowMatch = [regex]::Match($line, '^\s*"([^"]+)"\s*:\s*"allow"\s*,?\s*$')
            if ($allowMatch.Success) {
                $sectionAllows[$section] += $allowMatch.Groups[1].Value
            }
        }
    }
    foreach ($sec in @("edit", "read")) {
        $allows = @($sectionAllows[$sec])
        foreach ($pathValue in $allows) {
            if ($pathValue -eq "*" -or $pathValue -like "**/*") { continue }
            if ($pathValue -match '^[A-Za-z]:[\\/]') { continue }
            if ($allows -notcontains "**/$pathValue") {
                $missingCounterparts += "$($agentFile.Name) [$sec]: $pathValue"
            }
        }
    }
}
if ($agentFiles.Count -eq 0) {
    Write-Warn "no global harness agent files found; **/ path check skipped"
}
elseif ($missingCounterparts.Count -eq 0) {
    Write-Ok "role edit/read allow paths have **/ counterparts"
}
else {
    Write-Warn "role allow paths without **/ counterparts: $($missingCounterparts -join '; ')"
}

$configPath = Join-Path $GlobalRoot "opencode.jsonc"
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
if (Test-Path -LiteralPath $configPath) {
    $config = Get-Content -LiteralPath $configPath -Raw
    if ($config -match '"task"\s*:') {
        $notAllowed = @($harnessIds | Where-Object {
            $config -notmatch ('"' + [regex]::Escape($_) + '"\s*:\s*"allow"')
        })
        if ($notAllowed.Count -eq 0) {
            Write-Ok "permission.task allows all harness roles"
        }
        else {
            Write-Warn "permission.task does not allow: $($notAllowed -join ', ')"
        }
    }
    else {
        Write-Warn "no permission.task block in opencode.jsonc; run install.ps1 for explicit allow rules"
    }

    $selfSessionRoles = @("harness-analyst", "harness-coder")
    $crossRole = @()
    foreach ($agentFile in $agentFiles) {
        $roleName = [System.IO.Path]::GetFileNameWithoutExtension($agentFile.Name)
        $inTask = $false
        $taskAllows = @()
        foreach ($line in (Get-Content -LiteralPath $agentFile.FullName)) {
            if ($line -match '^\s{2}([A-Za-z0-9_-]+):') {
                $inTask = ($Matches[1] -eq "task")
                continue
            }
            if ($line -match '^[A-Za-z0-9_-]+:') { $inTask = $false; continue }
            if ($inTask) {
                $allowMatch = [regex]::Match($line, '^\s+"([^"]+)"\s*:\s*"allow"')
                if ($allowMatch.Success) { $taskAllows += $allowMatch.Groups[1].Value }
            }
        }
        if ($selfSessionRoles -contains $roleName) {
            if ($taskAllows -contains $roleName) {
                Write-Ok "$roleName may spawn self-sub-sessions"
            }
            else {
                Write-Warn "$roleName lacks self task allow; chunked self-sub-sessions will fail"
            }
        }
        if ($roleName -ne "harness") {
            foreach ($allowed in $taskAllows) {
                if ($allowed -like "harness-*" -and $allowed -ne $roleName) {
                    $crossRole += "$roleName -> $allowed"
                }
            }
        }
    }
    if ($crossRole.Count -eq 0) {
        Write-Ok "no cross-role task allows"
    }
    else {
        Write-Warn "cross-role task allows found: $($crossRole -join '; ')"
    }

    if ($config -match '"plantuml-render"') { Write-Ok "MCP plantuml-render configured" } else { Write-Warn "MCP plantuml-render not found in config" }
    if ($config -match '"local-rag"') { Write-Ok "MCP local-rag configured" } else { Write-Warn "MCP local-rag not found in config" }
    if ($config -match 'qwen3\.8:27b-64k') { Write-Ok "model qwen3.8:27b-64k declared" } else { Write-Warn "model qwen3.8:27b-64k not found in config" }
    if ($config -match 'tiel-coder:35b-a3b-mtp-128k-text') { Write-Ok "tiel-coder text model declared" } else { Write-Warn "tiel-coder text model not found in config" }
    if ($config -match 'tiel-coder:35b-a3b-mtp-128k-vision') { Write-Ok "tiel-coder vision model declared" } else { Write-Warn "tiel-coder vision model not found in config" }

    if (-not $SkipModelProbe) {
        $roleModels = @()
        $agentDir = Join-Path $GlobalRoot "agents"
        Get-ChildItem -LiteralPath $agentDir -Filter "harness*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
            $modelLine = Select-String -LiteralPath $_.FullName -Pattern '^model:\s*(\S+)' | Select-Object -First 1
            if ($modelLine) {
                $model = $modelLine.Matches[0].Groups[1].Value
                if ($model -match '/') { $model = ($model -split '/', 2)[1] }
                $roleModels += $model
            }
        }
        $roleModels = @($roleModels | Sort-Object -Unique)
        if ($roleModels.Count -eq 0) {
            Write-Warn "cannot find harness role models in global agents; model context probe skipped"
        }
        elseif (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
            Write-Warn "ollama not found in PATH; model context probe skipped"
        }
        else {
            foreach ($model in $roleModels) {
                $actual = Get-OllamaNumCtx -Model $model
                if ($null -eq $actual) {
                    Write-Warn "model $model`: cannot read num_ctx from 'ollama show'"
                    continue
                }
                $configured = @(Get-ConfiguredContextValues -ConfigText $config -Model $model)
                if ($configured.Count -eq 0) {
                    Write-Warn "model $model`: no limit.context in opencode.jsonc (actual num_ctx $actual)"
                    continue
                }
                $tooHigh = @($configured | Where-Object { $_ -gt $actual })
                if ($tooHigh.Count -gt 0) {
                    Write-Warn "model $model`: limit.context $($tooHigh -join '/') > actual num_ctx $actual; opencode may not compact before the real limit"
                }
                else {
                    $maxConfigured = ($configured | Measure-Object -Maximum).Maximum
                    if ($maxConfigured -lt $actual) {
                        Write-Info "model $model`: limit.context $maxConfigured < actual num_ctx $actual (safe, context underused)"
                    }
                    else {
                        Write-Ok "model $model`: limit.context matches actual num_ctx $actual"
                    }
                }
            }
        }
    }
    else {
        Write-Info "model context probe skipped (-SkipModelProbe)"
    }

    $pluginPath = Join-Path $GlobalRoot "plugins\qwen-compaction-handoff.js"
    if (Test-Path -LiteralPath $pluginPath) {
        $plugin = Get-Content -LiteralPath $pluginPath -Raw
        $unsafe = [regex]::Match($plugin, 'client\.session\.create\s*\([\s\S]{0,1200}?body\s*:\s*\{[^}]*parentID')
        if ($unsafe.Success) {
            Write-Warn "compaction handoff creates child continuation sessions (parentID); 'task' may hit the subagent depth limit"
        }
        else {
            Write-Ok "compaction handoff does not create child continuation sessions"
        }
    }
    else {
        Write-Info "no qwen-compaction-handoff.js plugin; compaction depth check skipped"
    }
    $depthMatch = [regex]::Match($config, '"subagent_depth"\s*:\s*(\d+)')
    if ($depthMatch.Success) {
        $depth = [int]$depthMatch.Groups[1].Value
        if ($depth -ge 2) {
            Write-Ok "subagent_depth is $depth (self-sub-sessions enabled)"
        }
        else {
            Write-Warn "subagent_depth is $depth; self-sub-sessions require >= 2"
        }
    }
    else {
        Write-Warn "subagent_depth not set; run install.ps1 or add top-level `"subagent_depth`": 2"
    }

    $ragKey = [regex]::Match($config, '"local-rag"\s*:\s*\{')
    if ($ragKey.Success) {
        $ragOpen = $config.IndexOf('{', $ragKey.Index)
        $ragBlock = if ($ragOpen -ge 0) { Get-BraceBlock -Text $config -OpenIndex $ragOpen } else { $null }
        if ($ragBlock) {
            $timeoutMatch = [regex]::Match($ragBlock, '"timeout"\s*:\s*(\d+)')
            if ($timeoutMatch.Success) {
                $timeout = [int]$timeoutMatch.Groups[1].Value
                if ($timeout -le 120000) {
                    Write-Warn "local-rag timeout is $timeout ms; large syncs may exceed it (ISSUE-20261111-100017). Consider >=180000 or async sync."
                }
                else {
                    Write-Ok "local-rag timeout is $timeout ms"
                }
            }
            else {
                Write-Info "local-rag timeout is not set; MCP default may be too short for large syncs"
            }
        }
    }
}
else {
    Write-Warn "$configPath not found; harness allow rules are not configured"
}

$marker = Join-Path $Project "harness\process.md"
$plan = Join-Path $Project "docs\plan.md"
$projectVersionPath = Join-Path $Project "harness\version.json"
if ((Test-Path -LiteralPath $marker) -and (Test-Path -LiteralPath $plan)) {
    Write-Ok "project initialized as harness"
    if (Test-Path -LiteralPath $projectVersionPath) {
        try {
            $globalVersion = Get-Content -LiteralPath (Join-Path $GlobalHarness "version.json") -Raw | ConvertFrom-Json
            $projectVersion = Get-Content -LiteralPath $projectVersionPath -Raw | ConvertFrom-Json
            if ($globalVersion.version -eq $projectVersion.version) {
                Write-Ok "project version matches global ($($projectVersion.version))"
            }
            else {
                Write-Warn "project version $($projectVersion.version) differs from global $($globalVersion.version)"
            }
        }
        catch {
            Write-Warn "failed to read versions: $_"
        }
    }
    else {
        Write-Warn "no harness/version.json; run /harness-init -Force or add the file"
    }
    $issuesIndex = Join-Path $Project "docs\issues\README.md"
    $issueTemplate = Join-Path $Project "harness\templates\issue.md"
    $issueScript = Join-Path $Project "harness\scripts\new-issue.ps1"
    if (Test-Path -LiteralPath $issuesIndex) {
        Write-Ok "issue log docs/issues/README.md exists"
    }
    else {
        Write-Warn "docs/issues/README.md not created yet; it will appear with the first issue"
    }
    $issuesDir = Join-Path $Project "docs\issues"
    $issueFiles = @(Get-ChildItem -LiteralPath $issuesDir -Filter "ISSUE-*.md" -File -ErrorAction SilentlyContinue)
    if (Test-Path -LiteralPath $issuesIndex) {
        $indexText = Get-Content -LiteralPath $issuesIndex -Raw
        $indexed = @([regex]::Matches($indexText, '\]\(([^)]+\.md)\)') | ForEach-Object { $_.Groups[1].Value })
        $missingRows = @($issueFiles | Where-Object { $indexed -notcontains $_.Name })
        $orphanRows = @($indexed | Where-Object {
            -not (Test-Path -LiteralPath (Join-Path $issuesDir $_))
        })
        if ($missingRows.Count -eq 0 -and $orphanRows.Count -eq 0) {
            Write-Ok "issue index matches $($issueFiles.Count) issue file(s)"
        }
        else {
            if ($missingRows.Count -gt 0) {
                Write-Warn "issue index is missing rows for: $($missingRows.Name -join ', ')"
            }
            if ($orphanRows.Count -gt 0) {
                Write-Warn "issue index has orphan rows: $($orphanRows -join ', ')"
            }
        }
    }
    $strayIssueDir = Join-Path $Project "harness-issues"
    if (Test-Path -LiteralPath $strayIssueDir) {
        Write-Warn "root harness-issues/ exists; issue records belong only in docs/issues/"
    }
    $strayIssueFiles = @(Get-ChildItem -LiteralPath $Project -Filter "ISSUE-*.md" -File -ErrorAction SilentlyContinue)
    if ($strayIssueFiles.Count -gt 0) {
        Write-Warn "issue files outside docs/issues/: $($strayIssueFiles.Name -join ', ')"
    }
    if ((Test-Path -LiteralPath $issueTemplate) -and (Test-Path -LiteralPath $issueScript)) {
        Write-Ok "issue template and new-issue.ps1 available in the project"
    }
    else {
        Write-Warn "missing harness/templates/issue.md or harness/scripts/new-issue.ps1; run /harness-init -Force"
    }
    $budgetScript = Join-Path $Project "harness\scripts\check-budget.ps1"
    $e2eValidator = Join-Path $Project "harness\scripts\validate-e2e-data.py"
    if ((Test-Path -LiteralPath $budgetScript) -and (Test-Path -LiteralPath $e2eValidator)) {
        Write-Ok "budget check and e2e data validator available in the project"
    }
    else {
        Write-Warn "missing harness/scripts/check-budget.ps1 or validate-e2e-data.py; run /harness-init -Force"
    }
    $newTemplates = @(
        "checkpoint.md", "e2e-use-case.md", "e2e-test-data.yaml", "ux-spec.md",
        "task-card-feature.md", "task-card-bugfix.md", "bug-card.md"
    )
    $missingTemplates = @($newTemplates | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $Project "harness\templates\$_"))
    })
    if ($missingTemplates.Count -eq 0) {
        Write-Ok "checkpoint, e2e, UX, workflow task, and bug templates available in the project"
    }
    else {
        Write-Warn "missing project templates: $($missingTemplates -join ', '); run /harness-init -Force"
    }
    $missingWorkflows = @(@("feature.md", "bugfix.md") | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $Project "harness\workflows\$_"))
    })
    if ($missingWorkflows.Count -eq 0) {
        Write-Ok "feature and bugfix workflows available in the project"
    }
    else {
        Write-Warn "missing project workflows: $($missingWorkflows -join ', '); run /harness-init -Force"
    }
    $bugsIndex = Join-Path $Project "docs\bugs\README.md"
    if (Test-Path -LiteralPath $bugsIndex) {
        Write-Ok "product bug registry docs/bugs/README.md exists"
    }
    else {
        Write-Warn "docs/bugs/README.md not found; run /harness-init -Force"
    }
    $missingDirs = @(@("ux", "checkpoints", "bugs") | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $Project "docs\$_"))
    })
    if ($missingDirs.Count -eq 0) {
        Write-Ok "docs/ux, docs/checkpoints, and docs/bugs directories exist"
    }
    else {
        Write-Warn "missing docs directories: $($missingDirs -join ', '); run /harness-init -Force"
    }
}
else {
    Write-Warn "current project is not initialized: no harness/process.md or docs/plan.md; run /harness-init"
}

$oldIds = @("analyst.md", "architect.md", "coder.md", "qa.md", "doc-writer.md", "orchestrator.md")
$oldFiles = @()
foreach ($name in $oldIds) {
    $path = Join-Path $Project ".opencode\agents\$name"
    if (Test-Path -LiteralPath $path) { $oldFiles += $path }
}
if ($oldFiles.Count -eq 0) {
    Write-Ok "no old project agent copies with IDs without the harness- prefix"
}
else {
    Write-Warn "found old project agent copies (may bypass gating):"
    $oldFiles | ForEach-Object { Write-Host "       $_" }
}

if (Get-Command opencode -ErrorAction SilentlyContinue) { Write-Ok "opencode found in PATH" } else { Write-Warn "opencode not found in PATH" }
if (Get-Command ollama -ErrorAction SilentlyContinue) { Write-Ok "ollama found in PATH" } else { Write-Warn "ollama not found in PATH; check local models" }

Write-Host ""
if ($script:critical) {
    Write-Host "Result: critical harness installation problems." -ForegroundColor Red
    exit 1
}
Write-Host "Result: no critical problems; review warnings above." -ForegroundColor Green
exit 0
