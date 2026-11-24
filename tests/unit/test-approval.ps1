#requires -Version 5.1
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$lib = Join-Path $root "harness\scripts\harness-lib.ps1"
if (-not (Test-Path -LiteralPath $lib)) { throw "harness lib not found: $lib" }
. $lib

function Assert-Decision {
    param($Case, [bool]$Approved, [string]$Reason)
    $params = @{}
    foreach ($key in $Case.Keys) { if ($key -ne 'Name') { $params[$key] = $Case[$key] } }
    $r = Get-ApprovalDecision @params
    if ($r.Approved -ne $Approved) {
        throw "decision mismatch for '$($Case.Name)': got $($r.Approved), expected $Approved ($($r.Reason))"
    }
    if ($Reason -and $r.Reason -notlike "*$Reason*") {
        throw "reason mismatch for '$($Case.Name)': $($r.Reason)"
    }
}

Assert-Decision @{ Name = 'legacy final'; PolicyMode = 'legacy'; IsFinal = $true; Fail = 0; Manual = 0; Unchecked = 0 } $false 'requires the user'
Assert-Decision @{ Name = 'legacy final auto'; PolicyMode = 'legacy'; IsFinal = $true; Fail = 0; Manual = 0; Unchecked = 0; AutoApprove = $true } $true 'auto-approved'
Assert-Decision @{ Name = 'legacy UX'; PolicyMode = 'legacy'; LegacyUxGate = $true; Fail = 0; Manual = 0; Unchecked = 0 } $false 'requires the user'
Assert-Decision @{ Name = 'legacy intermediate'; PolicyMode = 'legacy'; Fail = 0; Manual = 0; Unchecked = 0 } $true 'auto-approved'
Assert-Decision @{ Name = 'risk medium'; PolicyMode = 'risk'; RiskTier = 'medium'; Fail = 0; Manual = 0; Unchecked = 0 } $true 'auto-approved'
Assert-Decision @{ Name = 'risk high batch'; PolicyMode = 'risk'; RiskTier = 'high'; ReviewGroup = 'RG-BUILD'; Fail = 0; Manual = 0; Unchecked = 0 } $true 'covered by the group gate'
Assert-Decision @{ Name = 'risk high gate'; PolicyMode = 'risk'; RiskTier = 'high'; ReviewGroup = 'RG-BUILD'; IsBatchGate = $true; Gate = 'Q-02 CP-2'; Fail = 0; Manual = 0; Unchecked = 0 } $false 'batch gate'
Assert-Decision @{ Name = 'risk critical'; PolicyMode = 'risk'; RiskTier = 'critical'; Fail = 0; Manual = 0; Unchecked = 0 } $false 'critical risk'
Assert-Decision @{ Name = 'risk UX gate'; PolicyMode = 'risk'; RiskTier = 'high'; IsUxGate = $true; Fail = 0; Manual = 0; Unchecked = 0 } $false 'UX gate'
Assert-Decision @{ Name = 'risk manual'; PolicyMode = 'risk'; RiskTier = 'medium'; Fail = 0; Manual = 1; Unchecked = 0 } $false 'manual review'
Assert-Decision @{ Name = 'risk fail'; PolicyMode = 'risk'; RiskTier = 'medium'; Fail = 1; Manual = 0; Unchecked = 0 } $false 'failed or unchecked'

$policy = Get-RiskPolicy -Root $root
if ($policy.Mode -notin @('legacy', 'risk')) { throw "unexpected policy mode: $($policy.Mode)" }
$groups = Get-ReviewGroups -Root $root
if (-not $groups.Exists) { throw "review groups not found" }
foreach ($workflow in @('feature', 'bugfix')) {
    foreach ($group in @(Get-JsonPropertyValue $groups.Data $workflow)) {
        if (-not $group) { continue }
        $stages = @(Get-JsonPropertyValue $group 'stages')
        if ($stages.Count -gt $policy.MaxBatchStages) { throw "group $($group.id) exceeds max_batch_stages" }
        if ($stages -notcontains (Get-JsonPropertyValue $group 'gate_stage')) { throw "group $($group.id) gate not in stages" }
    }
}
Write-Host "PASS test-approval"
