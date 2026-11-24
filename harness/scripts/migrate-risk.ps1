#requires -Version 5.1
<#
.SYNOPSIS
  Switch a project from legacy P2 checks to the risk/batch approval policy.

.DESCRIPTION
  Validates checks/review-groups.json, sets checks/risk-policy.json mode to
  "risk", and optionally recalculates hold:true for critical, human, and UX-gated
  stages. Existing checkpoints are not changed by this script.

.EXAMPLE
  .\migrate-risk.ps1 -DryRun
  .\migrate-risk.ps1 -UpdateHolds
#>
[CmdletBinding()]
param(
    [string]$Root = '',
    [switch]$UpdateHolds,
    [switch]$DryRun,
    [switch]$NoCommit,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "harness-lib.ps1")

if (-not $Root) { $Root = Get-HarnessRoot }
$Root = (Resolve-Path -LiteralPath $Root).Path
$policy = Get-RiskPolicy -Root $Root
if (-not $policy.Exists) { throw "risk policy not found: $($policy.Path)" }
$reviewGroups = Get-ReviewGroups -Root $Root
if (-not $reviewGroups.Exists) { throw "review groups not found: $($reviewGroups.Path)" }

foreach ($workflow in @('feature', 'bugfix', 'sdd')) {
    $defs = @((Get-JsonPropertyValue $reviewGroups.Data $workflow))
    foreach ($group in $defs) {
        if (-not $group) { continue }
        $id = [string](Get-JsonPropertyValue $group 'id')
        $stages = @((Get-JsonPropertyValue $group 'stages'))
        $gateStage = [string](Get-JsonPropertyValue $group 'gate_stage')
        $gateCheckpoint = [string](Get-JsonPropertyValue $group 'gate_checkpoint')
        if (-not $id -or $stages.Count -eq 0 -or -not $gateStage -or -not $gateCheckpoint) {
            throw "review group in workflow '$workflow' is missing id, stages, gate_stage, or gate_checkpoint"
        }
        if ($stages.Count -gt $policy.MaxBatchStages) {
            throw "review group $id has $($stages.Count) stages; max_batch_stages is $($policy.MaxBatchStages)"
        }
        if ($stages -notcontains $gateStage) {
            throw "review group $id gate stage $gateStage is not in its stages"
        }
    }
}

if ($policy.Mode -eq 'risk' -and -not $UpdateHolds -and -not $Force) {
    Write-Host "risk policy is already active" -ForegroundColor Green
    exit 0
}

$data = $policy.Data
if ($null -eq $data) { throw "risk policy has no JSON data" }
$data | Add-Member -NotePropertyName mode -NotePropertyValue 'risk' -Force
$policyText = ($data | ConvertTo-Json -Depth 20) + "`r`n"

$holdChanges = @()
if ($UpdateHolds) {
    $uxGates = @((Get-JsonPropertyValue $data 'ux_gates'))
    foreach ($card in @(Get-CardEntries -Root $Root)) {
        $stage = [string](Get-JsonPropertyValue $card 'stage')
        $workflow = [string](Get-JsonPropertyValue $card 'workflow')
        if (-not $stage -or -not $workflow) { continue }
        $cardFields = @{}
        foreach ($prop in $card.PSObject.Properties) { $cardFields[$prop.Name] = [string]$prop.Value }
        $risk = Get-RiskAssessment -Root $Root -Task ([string](Get-JsonPropertyValue $card 'id')) `
            -Workflow $workflow -Stage $stage -Card $cardFields -CardPath ([string](Get-JsonPropertyValue $card 'path')) `
            -Policy $policy -ReviewGroups $reviewGroups
        $uxGate = @($uxGates | Where-Object { $_ -like "$stage`:*" }).Count -gt 0
        $wantHold = ($risk.RiskTier -eq 'critical') -or ($risk.ReviewMode -eq 'human') -or $uxGate
        $current = ([string](Get-JsonPropertyValue $card 'hold')).Trim().ToLowerInvariant()
        $currentBool = ($current -eq 'true')
        if ($wantHold -and -not $currentBool) {
            $holdChanges += [pscustomobject]@{
                Task   = [string](Get-JsonPropertyValue $card 'id')
                Stage  = $stage
                Old    = $currentBool
                New    = $wantHold
                Tier   = $risk.RiskTier
                Reason = if ($uxGate) { 'UX gate' } elseif ($risk.ReviewMode -eq 'human') { 'review_mode human' } else { 'critical risk' }
                Path   = [string](Get-JsonPropertyValue $card 'path')
            }
        }
    }
}

if ($DryRun) {
    Write-Host "--- migrate-risk (dry run) ---" -ForegroundColor Cyan
    Write-Host "policy: $($policy.Path) -> mode risk"
    if ($UpdateHolds) {
        if ($holdChanges.Count -eq 0) { Write-Host "holds: no changes" }
        else { $holdChanges | Format-Table Task, Stage, Old, New, Tier, Reason -AutoSize | Out-String | Write-Host }
    }
    exit 0
}

Write-Utf8NoBom $policy.Path $policyText
Write-Host "policy: $($policy.Path) -> risk" -ForegroundColor Green

if ($UpdateHolds) {
    foreach ($change in $holdChanges) {
        $null = Set-CardField -Path $change.Path -Name 'hold' -Value ($(if ($change.New) { 'true' } else { 'false' }))
        $line = ('- {0}: hold recalculated {1} -> {2} ({3}; {4})' -f (Get-Date -Format 'yyyy-MM-dd'), $change.Old, $change.New, $change.Tier, $change.Reason)
        $text = (Read-Utf8 $change.Path).TrimEnd([char[]]"`r`n") + "`r`n" + $line + "`r`n"
        Write-Utf8NoBom $change.Path $text
        Write-Host ("hold: {0} {1} -> {2} ({3})" -f $change.Task, $change.Old, $change.New, $change.Reason)
    }
}

if ($NoCommit) {
    Write-Host "commit skipped (-NoCommit)" -ForegroundColor Yellow
    exit 0
}

$commitPaths = @($policy.Path)
foreach ($change in $holdChanges) { $commitPaths += $change.Path }
$commitRel = @()
foreach ($path in $commitPaths) {
    if (Test-Path -LiteralPath $path) {
        $commitRel += ConvertTo-ForwardSlash ($path.Substring($Root.TrimEnd('\').Length + 1))
    }
}
$null = Invoke-Git -Root $Root -Arguments (@('add', '--') + $commitRel)
$staged = Invoke-Git -Root $Root -Arguments @('diff', '--cached', '--name-only') -AllowFail
if ($staged.Output.Count -eq 0) {
    Write-Host "nothing to commit" -ForegroundColor Yellow
    exit 0
}
$null = Invoke-Git -Root $Root -Arguments @('commit', '-m', 'chore: activate risk approval policy')
Write-Host "commit: chore: activate risk approval policy"
exit 0
