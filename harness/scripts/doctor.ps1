#requires -Version 5.1
<#
.SYNOPSIS
  Check the global harness installation and the current project.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$script:critical = $false

function Write-Ok($text) { Write-Host "[ok]   $text" -ForegroundColor Green }
function Write-Warn($text) { Write-Host "[warn] $text" -ForegroundColor Yellow }
function Write-Err($text) { Write-Host "[err]  $text" -ForegroundColor Red; $script:critical = $true }

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
    (Join-Path $GlobalHarness "scripts\new-issue.ps1")
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
    if ($config -match '"plantuml-render"') { Write-Ok "MCP plantuml-render configured" } else { Write-Warn "MCP plantuml-render not found in config" }
    if ($config -match '"local-rag"') { Write-Ok "MCP local-rag configured" } else { Write-Warn "MCP local-rag not found in config" }
    if ($config -match 'qwen3\.8:27b-64k') { Write-Ok "model qwen3.8:27b-64k declared" } else { Write-Warn "model qwen3.8:27b-64k not found in config" }
    if ($config -match 'tiel-coder:35b-a3b-mtp-128k-text') { Write-Ok "tiel-coder text model declared" } else { Write-Warn "tiel-coder text model not found in config" }
    if ($config -match 'tiel-coder:35b-a3b-mtp-128k-vision') { Write-Ok "tiel-coder vision model declared" } else { Write-Warn "tiel-coder vision model not found in config" }
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
    if ((Test-Path -LiteralPath $issueTemplate) -and (Test-Path -LiteralPath $issueScript)) {
        Write-Ok "issue template and new-issue.ps1 available in the project"
    }
    else {
        Write-Warn "missing harness/templates/issue.md or harness/scripts/new-issue.ps1; run /harness-init -Force"
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
