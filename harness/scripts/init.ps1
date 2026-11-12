#requires -Version 5.1
<#
.SYNOPSIS
  Initialize the harness in the current project.

.DESCRIPTION
  Creates harness/process.md, harness/workflows, harness/templates,
  harness/version.json, docs/plan.md, docs/activity.puml, and the docs/
  directory skeleton, including the product bug registry.
  Global agents and commands are not copied: the global installation is used.

.PARAMETER Force
  Overwrite existing harness files (with backup).
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text
    )
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

$UserProfile = [Environment]::GetFolderPath("UserProfile")
$GlobalRoot = Join-Path $UserProfile ".config\opencode"
$GlobalHarness = Join-Path $GlobalRoot "harness"
$Project = (Get-Location).Path
$HarnessDir = Join-Path $Project "harness"
$DocsDir = Join-Path $Project "docs"
$Marker = Join-Path $HarnessDir "process.md"
$PlanPath = Join-Path $DocsDir "plan.md"
$ActivityPath = Join-Path $DocsDir "activity.puml"

$requiredGlobal = @(
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
    (Join-Path $GlobalHarness "scripts\validate-e2e-data.py"),
    (Join-Path $GlobalRoot "agents\harness.md"),
    (Join-Path $GlobalRoot "agents\harness-ux-designer.md")
)
foreach ($item in $requiredGlobal) {
    if (-not (Test-Path -LiteralPath $item)) {
        throw "Global harness installation is incomplete: $item not found. Run harness/scripts/install.ps1 first."
    }
}

if ((Test-Path -LiteralPath $Marker) -and -not $Force) {
    throw "Harness is already initialized in $Project. Use -Force to overwrite (with backup)."
}

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if ($Force -and (Test-Path -LiteralPath $HarnessDir)) {
    $backup = Join-Path $Project ".harness-backup-$Timestamp"
    New-Item -ItemType Directory -Force -Path $backup | Out-Null
    Copy-Item -LiteralPath $HarnessDir -Destination (Join-Path $backup "harness") -Recurse -Force
    if (Test-Path -LiteralPath $PlanPath) {
        Copy-Item -LiteralPath $PlanPath -Destination (Join-Path $backup "plan.md") -Force
    }
    if (Test-Path -LiteralPath $ActivityPath) {
        Copy-Item -LiteralPath $ActivityPath -Destination (Join-Path $backup "activity.puml") -Force
    }
    Write-Host "Backup of existing files: $backup"
}

New-Item -ItemType Directory -Force -Path $HarnessDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $HarnessDir "templates") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $HarnessDir "workflows") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $HarnessDir "scripts") | Out-Null
foreach ($sub in @("tasks", "analysis", "ux", "architecture", "qa", "guides", "issues", "checkpoints", "bugs")) {
    New-Item -ItemType Directory -Force -Path (Join-Path $DocsDir $sub) | Out-Null
}

Copy-Item -Path (Join-Path $GlobalHarness "process.md") -Destination $HarnessDir -Force
Copy-Item -Path (Join-Path $GlobalHarness "templates\*") -Destination (Join-Path $HarnessDir "templates") -Force
Copy-Item -Path (Join-Path $GlobalHarness "workflows\*") -Destination (Join-Path $HarnessDir "workflows") -Force
Copy-Item -Path (Join-Path $GlobalHarness "scripts\new-issue.ps1") -Destination (Join-Path $HarnessDir "scripts") -Force
Copy-Item -Path (Join-Path $GlobalHarness "scripts\check-budget.ps1") -Destination (Join-Path $HarnessDir "scripts") -Force
Copy-Item -Path (Join-Path $GlobalHarness "scripts\validate-e2e-data.py") -Destination (Join-Path $HarnessDir "scripts") -Force

$issuesIndex = Join-Path $DocsDir "issues\README.md"
if (-not (Test-Path -LiteralPath $issuesIndex)) {
    $issuesHeader = @'
# Issues

| ID | Summary | Severity | Status | Location | Source | Updated |
|---|---|---|---|---|---|---|
'@
    Write-Utf8NoBom -Path $issuesIndex -Text ($issuesHeader + "`r`n")
}

$bugsIndex = Join-Path $DocsDir "bugs\README.md"
if (-not (Test-Path -LiteralPath $bugsIndex)) {
    $bugsHeader = @'
# Product Bugs

Product defect registry for this project. One `BUG-XXX` card per bug, created
from `harness/templates/bug-card.md` via `/harness-bug`; harness problems belong
in `docs/issues/`.

| ID | Summary | Severity | Status | Tasks | Updated |
|---|---|---|---|---|---|
'@
    Write-Utf8NoBom -Path $bugsIndex -Text ($bugsHeader + "`r`n")
}

$version = Get-Content -LiteralPath (Join-Path $GlobalHarness "version.json") -Raw | ConvertFrom-Json
$version | Add-Member -NotePropertyName initialized_at -NotePropertyValue ((Get-Date).ToString("o")) -Force
$version | Add-Member -NotePropertyName project -NotePropertyValue $Project -Force
Write-Utf8NoBom -Path (Join-Path $HarnessDir "version.json") -Text (($version | ConvertTo-Json -Depth 10) + "`r`n")

if (-not (Test-Path -LiteralPath $PlanPath)) {
    $plan = @'
# Plan (board)

Process rules: `harness/process.md`.
Workflows: `harness/workflows/feature.md`, `harness/workflows/bugfix.md`.
Derived diagram: `docs/activity.puml`. Informational only; update it from the
board after every task, never use it as a status source.

## Status legend

| Status | Diagram color | Meaning |
|---|---|---|
| `pending` | gray `#D3D3D3` | not started |
| `in_progress` | yellow `#FFE082` | in progress |
| `awaiting_review` | blue `#87CEFA` | waiting for user checkpoint review |
| `done` | green `#90EE90` | completed |
| `failed` | red `#FF9090` | error, fix required |
| `blocked` | orange `#FFB347` | external blocker |

At most one task is active (`in_progress` or `awaiting_review`) across both workflows.

## Board

| ID | Workflow | Task | Role | Dependencies | Status | Bug | Artifacts | Commit |
|---|---|---|---|---|---|---|---|---|
'@
    Write-Utf8NoBom -Path $PlanPath -Text ($plan + "`r`n")
}

if (-not (Test-Path -LiteralPath $ActivityPath)) {
    $activity = @'
@startuml
skinparam defaultFontName Segoe UI
skinparam ActivityBackgroundColor #FFFFFF
skinparam ActivityBorderColor #555555
skinparam ArrowColor #555555
title Local harness - task plan

' Derived visualization only; the board/card is authoritative.
' Status color: :task text; <<#RRGGBB>> (prefix #RRGGBB:text; is deprecated)
start
:No tasks;
stop

legend right
|= Color |= Status |
|<#90EE90>| done |
|<#FFE082>| in_progress |
|<#87CEFA>| awaiting_review |
|<#D3D3D3>| pending |
|<#FF9090>| failed |
|<#FFB347>| blocked |
endlegend
@enduml
'@
    Write-Utf8NoBom -Path $ActivityPath -Text ($activity + "`r`n")
}

$tasksReadme = Join-Path $DocsDir "tasks\README.md"
if (-not (Test-Path -LiteralPath $tasksReadme)) {
    $text = @'
# Tasks

Task cards are created from `harness/templates/task-card-feature.md` or
`harness/templates/task-card-bugfix.md`; `task-card.md` is a deprecation pointer.
File name: `T-XXX-<slug>.md`. Status and log live in the card.
Cards declare `workflow`, `stage`, `inputs`, e2e/UX or bug/severity applicability,
and at least one checkpoint; `CP-F` is mandatory.
Product bugs live in `docs/bugs/`; harness problems live in `docs/issues/`.
Checkpoint reviews are recorded in `docs/checkpoints/T-XXX-CP-N.md` from `harness/templates/checkpoint.md`.
'@
    Write-Utf8NoBom -Path $tasksReadme -Text ($text + "`r`n")
}

foreach ($sub in @("analysis", "ux", "architecture", "qa", "guides", "checkpoints")) {
    $keep = Join-Path $DocsDir "$sub\.gitkeep"
    if (-not (Test-Path -LiteralPath $keep)) {
        Write-Utf8NoBom -Path $keep -Text ""
    }
}

Write-Host ""
Write-Host "Harness initialized in project: $Project"
Write-Host "  process:  $Marker"
Write-Host "  board:    $PlanPath"
Write-Host "  activity: $ActivityPath"
Write-Host "  issues:   $issuesIndex"
Write-Host "  bugs:     $bugsIndex"
Write-Host "  version:  $(Join-Path $HarnessDir 'version.json')"
Write-Host ""
Write-Host "Next: run /harness-feature <slug> or /harness-bug <report>,"
Write-Host "then /harness-run T-XXX."
