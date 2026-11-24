#requires -Version 5.1
<#
.SYNOPSIS
  Record a human checkpoint decision for harness.

.DESCRIPTION
  This is the only writer of human approval decisions. It validates the checks
  summary, requires -AcknowledgeManual for MANUAL items, updates the checkpoint,
  card, board, and activity, optionally reopens selected tasks, and commits.

.EXAMPLE
  .\approve.ps1 -Task T-005 -Checkpoint CP-2 -Decision approved
  .\approve.ps1 -Task T-006 -Checkpoint CP-1 -Decision changes_requested -Remarks "Fix edge cases"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Task,
    [string]$Checkpoint = '',
    [ValidateSet('approved', 'changes_requested', 'rejected')][string]$Decision = 'approved',
    [string]$Reviewer = 'user',
    [string]$Remarks = '',
    [string[]]$Reopen = @(),
    [string]$Root = '',
    [switch]$AcknowledgeManual,
    [switch]$DryRun,
    [switch]$NoCommit,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "harness-lib.ps1")

if (-not $Root) { $Root = Get-HarnessRoot }
$Root = (Resolve-Path -LiteralPath $Root).Path
if ($Reviewer -match '(?i)^auto') { throw "approve.ps1 records human decisions only; reviewer cannot start with 'auto'" }

$cardPath = Get-CardFile -Root $Root -Task $Task
if (-not $cardPath) { throw "task card not found for $Task" }
$card = Get-CardFields -Path $cardPath
$stage = (($card['stage'] -split '/')[0]).Trim()
$workflow = if ($card.ContainsKey('workflow')) { $card['workflow'].Trim() } else { 'feature' }
$finalCheckpoint = if ($card.ContainsKey('final_checkpoint')) { $card['final_checkpoint'].Trim() } else { '' }
if (-not $Checkpoint) {
    $taskOpen = @(Get-OpenCheckpoints -Root $Root | Where-Object { $_.Task -eq $Task })
    if ($taskOpen.Count -eq 1) { $Checkpoint = $taskOpen[0].Checkpoint }
    elseif ($taskOpen.Count -eq 0) { throw "no checkpoint is awaiting review for $Task" }
    else { throw "multiple checkpoints are awaiting review for $Task; pass -Checkpoint" }
}
$cpPath = Get-CheckpointFile -Root $Root -Task $Task -Checkpoint $Checkpoint
if (-not $cpPath) { throw "checkpoint $Task $Checkpoint not found" }
$cp = Get-CheckpointFields -Path $cpPath
$currentStatus = [string](Get-JsonPropertyValue $cp 'status')
if ($currentStatus -ne 'awaiting_review' -and -not $Force) {
    throw "checkpoint $Task $Checkpoint status is '$currentStatus'; use -Force to override"
}

$checksRel = "docs/checkpoints/$Task-$Checkpoint.checks.json"
$checksPath = Join-Path $Root ($checksRel -replace '/', '\')
$fail = 0; $manual = 0; $unchecked = 0
if (Test-Path -LiteralPath $checksPath) {
    $checks = Read-Utf8 $checksPath | ConvertFrom-Json
    $fail = [int]$checks.summary.fail
    $manual = [int]$checks.summary.manual
    $unchecked = [int]$checks.summary.unchecked
}
else {
    Write-Host "[warn] $checksRel not found; approving without machine summary" -ForegroundColor Yellow
}
if ($Decision -eq 'approved') {
    if ($fail -gt 0 -or $unchecked -gt 0) { throw "cannot approve with FAIL=$fail or UNCHECKED=$unchecked" }
    if ($manual -gt 0 -and -not $AcknowledgeManual) {
        throw "cannot approve $manual MANUAL item(s) without -AcknowledgeManual"
    }
}

$isFinal = ($Checkpoint -eq 'CP-F') -or ($finalCheckpoint -and $Checkpoint -eq $finalCheckpoint)
$riskTier = [string](Get-JsonPropertyValue $cp 'risk_tier')
if (-not $riskTier -or $riskTier -eq '-') { $riskTier = '-' }
$policyMode = [string](Get-JsonPropertyValue $cp 'policy_mode')
if (-not $policyMode -or $policyMode -eq '-') { $policyMode = 'legacy' }
$reviewGroup = [string](Get-JsonPropertyValue $cp 'review_group')
if (-not $reviewGroup) { $reviewGroup = '-' }
$now = Get-Date
$nowText = $now.ToString('yyyy-MM-ddTHH:mm:ss')
$cpStatus = if ($Decision -eq 'approved') { 'approved' } else { $Decision }
$cardStatus = if ($Decision -eq 'approved') { if ($isFinal) { 'done' } else { 'in_progress' } }
elseif ($Decision -eq 'rejected') { 'failed' }
else { 'in_progress' }
$manualAck = if ($manual -gt 0 -and $AcknowledgeManual) { 'yes' } else { 'no' }
$reason = if ($Decision -eq 'approved') { 'human approved the checkpoint' } else { "human set $Decision" }
if ($Remarks) { $reason = $reason + ': ' + $Remarks }

$cpRel = ConvertTo-ForwardSlash ($cpPath.Substring($Root.TrimEnd('\').Length + 1))
$cardRel = ConvertTo-ForwardSlash ($cardPath.Substring($Root.TrimEnd('\').Length + 1))
$planned = @(
    "checkpoint: $cpRel",
    "status: $cpStatus",
    "task status: $cardStatus",
    "reviewer: $Reviewer",
    "decision: $Decision",
    "manual_ack: $manualAck"
)
if ($Remarks) { $planned += "remarks: $Remarks" }
if ($Reopen.Count -gt 0) { $planned += "reopen: $($Reopen -join ', ')" }

if ($DryRun) {
    Write-Host "--- approval (dry run) ---" -ForegroundColor Cyan
    $planned | ForEach-Object { Write-Output $_ }
    exit 0
}

$null = Set-CheckpointField -Path $cpPath -Name 'status' -Value $cpStatus
$null = Set-CheckpointField -Path $cpPath -Name 'reviewed_at' -Value $nowText
$null = Set-CheckpointField -Path $cpPath -Name 'reviewer' -Value $Reviewer
$null = Set-CheckpointField -Path $cpPath -Name 'decision' -Value $Decision
$null = Set-CheckpointField -Path $cpPath -Name 'approval_reason' -Value $reason
$null = Set-CheckpointField -Path $cpPath -Name 'manual_ack' -Value $manualAck
if ($Remarks) {
    Add-MarkdownSectionItem -Path $cpPath -Heading 'User remarks' -Item ("- {0} {1}: {2}" -f $nowText, $Reviewer, $Remarks)
}

$null = Set-CardCheckpointRow -Path $cardPath -Checkpoint $Checkpoint -Status $cpStatus -ReviewFile $cpRel -Checks $null
$null = Set-CardField -Path $cardPath -Name 'status' -Value $cardStatus
$boardChanged = Set-BoardRow -Root $Root -Task $Task -Values @{ status = $cardStatus }
if ($boardChanged -eq 0) { Write-Host "[warn] board row not found for $Task; update docs/plan.md manually" -ForegroundColor Yellow }

$logLine = ('- {0}: {1} {2} ({3}); decision {4}; reviewer {5}; policy {6}; risk {7}; group {8}' -f `
        (Get-Date -Format 'yyyy-MM-dd'), $Checkpoint, $cpStatus, $stage, $Decision, $Reviewer, $policyMode, $riskTier, $reviewGroup)
$cardText = (Read-Utf8 $cardPath).TrimEnd([char[]]"`r`n") + "`r`n" + $logLine + "`r`n"
Write-Utf8NoBom $cardPath $cardText

$reopened = @()
foreach ($reopenTask in @($Reopen)) {
    if (-not $reopenTask -or $reopenTask -eq $Task) { continue }
    $reopenCardPath = Get-CardFile -Root $Root -Task $reopenTask
    if (-not $reopenCardPath) { Write-Host "[warn] reopen target not found: $reopenTask" -ForegroundColor Yellow; continue }
    $null = Set-CardField -Path $reopenCardPath -Name 'status' -Value 'pending'
    $null = Set-BoardRow -Root $Root -Task $reopenTask -Values @{ status = 'pending' }
    $reopenText = (Read-Utf8 $reopenCardPath).TrimEnd([char[]]"`r`n") + "`r`n" + ('- {0}: reopened by {1} decision at {2} {3}' -f (Get-Date -Format 'yyyy-MM-dd'), $Task, $Task, $Checkpoint) + "`r`n"
    Write-Utf8NoBom $reopenCardPath $reopenText
    $reopened += $reopenCardPath
}

$activity = Sync-Activity -Root $Root
if ($activity.Rendered) { Write-Host "activity: rendered $($activity.Svg)" -ForegroundColor Green }
else { Write-Host "activity: puml updated, render skipped ($($activity.Reason))" -ForegroundColor Yellow }

if ($NoCommit) {
    Write-Host "commit skipped (-NoCommit)" -ForegroundColor Yellow
    Write-Host "checkpoint: $cpRel"
    Write-Host "status: $cardStatus ($cpStatus)"
    exit 0
}

$commitPaths = New-Object System.Collections.Generic.List[string]
foreach ($p in @($cpRel, $cardRel, 'docs/plan.md', 'docs/activity.puml', 'docs/activity.svg')) {
    if (Test-Path -LiteralPath (Join-Path $Root $p)) { $commitPaths.Add($p) }
}
foreach ($p in $reopened) {
    $commitPaths.Add((ConvertTo-ForwardSlash ($p.Substring($Root.TrimEnd('\').Length + 1))))
}
$commitPaths = @($commitPaths | Sort-Object -Unique)
$null = Invoke-Git -Root $Root -Arguments (@('add', '--') + $commitPaths)
$staged = Invoke-Git -Root $Root -Arguments @('diff', '--cached', '--name-only') -AllowFail
if ($staged.Output.Count -eq 0) {
    Write-Host "nothing to commit" -ForegroundColor Yellow
    Write-Host "checkpoint: $cpRel"
    exit 0
}
$message = if ($Decision -eq 'approved') { "$Task`: approve $Checkpoint ($stage)" } else { "$Task`: $Decision $Checkpoint ($stage)" }
$null = Invoke-Git -Root $Root -Arguments @('commit', '-m', $message)
$head = Invoke-Git -Root $Root -Arguments @('rev-parse', '--short', 'HEAD')
$hash = ([string]$head.Output[0]).Trim()
$null = Set-BoardRow -Root $Root -Task $Task -Values @{ commit = $hash }
$null = Set-CardField -Path $cardPath -Name 'commit' -Value $hash
$cardText = (Read-Utf8 $cardPath).TrimEnd([char[]]"`r`n") + "`r`n" + "- $hash`: approval snapshot" + "`r`n"
Write-Utf8NoBom $cardPath $cardText
$null = Invoke-Git -Root $Root -Arguments (@('add', '--') + @($cpRel, 'docs/plan.md', $cardRel))
$null = Invoke-Git -Root $Root -Arguments @('commit', '-m', "$Task`: record $Checkpoint approval $hash")

Write-Host ""
Write-Host "checkpoint: $cpRel"
Write-Host "status: $cardStatus ($cpStatus)"
Write-Host "reviewer: $Reviewer"
Write-Host "decision: $Decision"
Write-Host "commit: $hash"
exit 0
