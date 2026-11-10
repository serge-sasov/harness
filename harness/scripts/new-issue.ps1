#requires -Version 5.1
<#
.SYNOPSIS
  Create a harness issue record in docs/issues and update the index.

.DESCRIPTION
  One call creates one MD file ISSUE-<timestamp>-<slug>.md from the
  harness/templates/issue.md template and adds a row to docs/issues/README.md.
  Requires an initialized harness project (harness/process.md or docs/plan.md).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Title,
    [ValidateSet("blocker", "major", "minor", "info")][string]$Severity = "major",
    [ValidateSet("open", "investigating", "workaround", "resolved", "wontfix")][string]$Status = "open",
    [ValidateSet("permission", "tool", "model", "mcp", "rag", "path", "git", "process", "other")][string]$Type = "other",
    [string]$Source = "unknown",
    [string]$Role = "unknown",
    [string]$Location = "not specified",
    [string]$Symptom = "Describe the symptoms, error text, and context.",
    [string]$RootCause = "Not identified.",
    [string]$Solution = "Not found.",
    [string]$Verification = "Not verified.",
    [string]$Prevention = "Not defined.",
    [string]$Links = "Task card, artifacts, commit - to be filled.",
    [string]$Environment = "",
    [switch]$NoIndex
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

function Table-Cell {
    param([AllowEmptyString()][string]$Value)
    if ($null -eq $Value) { return "" }
    return (($Value -replace '\|', '\|') -replace "`r?`n", " ").Trim()
}

$Project = (Get-Location).Path
$ProcessPath = Join-Path $Project "harness\process.md"
$PlanPath = Join-Path $Project "docs\plan.md"
if (-not (Test-Path -LiteralPath $ProcessPath) -and -not (Test-Path -LiteralPath $PlanPath)) {
    throw "Project is not initialized as harness: no harness/process.md or docs/plan.md. Run /harness-init."
}

$IssuesDir = Join-Path $Project "docs\issues"
New-Item -ItemType Directory -Force -Path $IssuesDir | Out-Null

$Now = Get-Date
$DetectedAt = $Now.ToString("o")
$Timestamp = $Now.ToString("yyyyMMdd-HHmmss")
$Id = "ISSUE-$Timestamp"
$IdSuffix = 2
while (Get-ChildItem -LiteralPath $IssuesDir -Filter "$Id-*" -File -ErrorAction SilentlyContinue) {
    $Id = "ISSUE-$Timestamp-$IdSuffix"
    $IdSuffix++
}

$Slug = ($Title.ToLowerInvariant() -replace '[^\w\-]+', '-') -replace '^-+|-+$', ''
if ([string]::IsNullOrWhiteSpace($Slug)) { $Slug = "issue" }
if ($Slug.Length -gt 60) { $Slug = $Slug.Substring(0, 60).TrimEnd('-') }
if ([string]::IsNullOrWhiteSpace($Slug)) { $Slug = "issue" }

$FileName = "$Id-$Slug.md"
$IssuePath = Join-Path $IssuesDir $FileName
$Suffix = 2
while (Test-Path -LiteralPath $IssuePath) {
    $FileName = "$Id-$Slug-$Suffix.md"
    $IssuePath = Join-Path $IssuesDir $FileName
    $Suffix++
}

if ([string]::IsNullOrWhiteSpace($Environment)) {
    $Environment = "OS: $([System.Environment]::OSVersion.VersionString); cwd: $Project"
}

$TemplatePath = Join-Path $Project "harness\templates\issue.md"
if (Test-Path -LiteralPath $TemplatePath) {
    $Template = Get-Content -LiteralPath $TemplatePath -Raw -Encoding UTF8
}
else {
    $Template = @'
# {{ID}}: {{TITLE}}

| Field | Value |
|---|---|
| id | {{ID}} |
| status | {{STATUS}} |
| severity | {{SEVERITY}} |
| type | {{TYPE}} |
| detected_at | {{DETECTED_AT}} |
| source | {{SOURCE}} |
| role | {{ROLE}} |
| location | {{LOCATION}} |
| environment | {{ENVIRONMENT}} |

## Symptoms

{{SYMPTOM}}

## Reproduction

1. 
2. 
3. 

## Expected / actual behavior

- Expected:
- Actual:

## Cause

{{ROOT_CAUSE}}

## Solution / workaround

{{SOLUTION}}

## Verification

{{VERIFICATION}}

## Prevention / follow-up

{{PREVENTION}}

## Links

{{LINKS}}

## Timeline

- {{DETECTED_AT}}: detected
'@
}

$Content = $Template
$Content = $Content.Replace("{{ID}}", $Id)
$Content = $Content.Replace("{{TITLE}}", $Title)
$Content = $Content.Replace("{{STATUS}}", $Status)
$Content = $Content.Replace("{{SEVERITY}}", $Severity)
$Content = $Content.Replace("{{TYPE}}", $Type)
$Content = $Content.Replace("{{DETECTED_AT}}", $DetectedAt)
$Content = $Content.Replace("{{SOURCE}}", (Table-Cell $Source))
$Content = $Content.Replace("{{ROLE}}", (Table-Cell $Role))
$Content = $Content.Replace("{{LOCATION}}", (Table-Cell $Location))
$Content = $Content.Replace("{{ENVIRONMENT}}", (Table-Cell $Environment))
$Content = $Content.Replace("{{SYMPTOM}}", $Symptom)
$Content = $Content.Replace("{{ROOT_CAUSE}}", $RootCause)
$Content = $Content.Replace("{{SOLUTION}}", $Solution)
$Content = $Content.Replace("{{VERIFICATION}}", $Verification)
$Content = $Content.Replace("{{PREVENTION}}", $Prevention)
$Content = $Content.Replace("{{LINKS}}", $Links)

Write-Utf8NoBom -Path $IssuePath -Text $Content

$IndexPath = Join-Path $IssuesDir "README.md"
if (-not (Test-Path -LiteralPath $IndexPath)) {
    $header = @'
# Issues

| ID | Summary | Severity | Status | Location | Source | Updated |
|---|---|---|---|---|---|---|
'@
    Write-Utf8NoBom -Path $IndexPath -Text ($header + "`r`n")
}

if (-not $NoIndex) {
    $link = "[$Id]($FileName)"
    $row = "| $link | $(Table-Cell $Title) | $Severity | $Status | $(Table-Cell $Location) | $(Table-Cell $Source) | $DetectedAt |"
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::AppendAllText($IndexPath, $row + "`r`n", $encoding)
}

Write-Host "Created issue: $IssuePath"
if (-not $NoIndex) { Write-Host "Index:         $IndexPath" }
Write-Host ""
Write-Host "Fill in cause, solution, verification, and prevention;"
Write-Host "pass ID $Id to harness-orchestrator for index and commit reconciliation."
