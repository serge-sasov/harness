#requires -Version 5.1
<#
.SYNOPSIS
Close a harness stage checkpoint deterministically.

.DESCRIPTION
Runs the deterministic checks, records hashes in the evidence ledger, renders the
checkpoint from machine data, applies the P2 approval policy, updates the board
and card, re-renders activity, and commits the snapshot.

Policy P2: an intermediate checkpoint with FAIL=0, UNCHECKED=0 and MANUAL=0 is
approved automatically (reviewer "auto (P2)"). CP-F and any checkpoint with
MANUAL items always require the user. A card with "hold: true" forces human
review for every checkpoint.

.EXAMPLE
.\stage-done.ps1 -Task T-005 -Checkpoint CP-F
.\stage-done.ps1 -Task T-006 -Checkpoint CP-1 -DryRun
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Task,
    [string]$Checkpoint = '',
    [string]$Root = '',
    [string]$ChecksDir = '',
    [switch]$AutoApprove,
    [switch]$DryRun,
    [switch]$NoCommit,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "harness-lib.ps1")

function Format-Cell {
    param([string]$Text)
    if ($null -eq $Text) { return '-' }
    (([string]$Text) -replace '\|', '\|' -replace "`r?`n", ' ').Trim()
}

function Get-CardStatusForCheckpoint {
    param([bool]$Approved, [bool]$IsFinal)
    if ($Approved -and $IsFinal) { return 'done' }
    if ($Approved) { return 'in_progress' }
    'awaiting_review'
}

if (-not $Root) { $Root = Get-HarnessRoot }
$Root = (Resolve-Path -LiteralPath $Root).Path
$cardPath = Get-CardFile -Root $Root -Task $Task
if (-not $cardPath) { throw "Task card not found for $Task in docs/tasks" }
$card = Get-CardFields -Path $cardPath
$stage = (($card['stage'] -split '/')[0]).Trim()
$workflow = if ($card.ContainsKey('workflow')) { $card['workflow'].Trim() } else { 'feature' }
$role = if ($card.ContainsKey('role')) { $card['role'].Trim() } else { 'orchestrator' }
$title = if ($card.ContainsKey('title')) { $card['title'].Trim() } else { $Task }
$cardStatus = if ($card.ContainsKey('status')) { $card['status'].Trim() } else { 'pending' }
$cardRels = (($card['artifacts'] -replace '`', '').Trim())
$bugValue = if ($card.ContainsKey('bug')) { $card['bug'] } else { '-' }

if (-not $stage) { throw "Card $Task has no stage" }
if (-not $Checkpoint) {
    if ($stage -in @('F-01', 'B-05')) { $Checkpoint = 'CP-F' }
    else { throw "Checkpoint is required for stage $stage (e.g. -Checkpoint CP-1)" }
}

if ($cardStatus -in @('done', 'failed', 'blocked') -and -not $Force) {
    Write-Host "[skip] $Task status is '$cardStatus'; use -Force to record a checkpoint anyway" -ForegroundColor Yellow
    exit 0
}

$cpRel = "docs/checkpoints/$Task-$Checkpoint.md"
$cpPath = Join-Path $Root $cpRel
$checksRel = "docs/checkpoints/$Task-$Checkpoint.checks.json"
$checksPath = if ($DryRun) { Join-Path ([System.IO.Path]::GetTempPath()) "$Task-$Checkpoint.checks.json" } else { Join-Path $Root $checksRel }
$ledgerRel = "docs/evidence/$Task.md"
$ledgerPath = Join-Path $Root $ledgerRel

if ((Test-Path -LiteralPath $cpPath) -and -not $Force) {
    $existingStatus = Get-CheckpointField -Path $cpPath -Name 'status'
    Write-Host "[skip] $cpRel already exists (status=$existingStatus); use -Force to regenerate" -ForegroundColor Yellow
    exit 0
}

Write-Host "stage-done $Task $Checkpoint ($workflow/$stage)" -ForegroundColor Cyan

$verifyArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'verify-artifacts.ps1'),
    '-Root', $Root, '-Task', $Task, '-Stage', $stage, '-Json', $checksPath)
if ($ChecksDir) { $verifyArgs += @('-ChecksDir', $ChecksDir) }
& powershell @verifyArgs
$verifyExit = $LASTEXITCODE
if (-not (Test-Path -LiteralPath $checksPath)) { throw "verify-artifacts did not write $checksPath" }
$checks = Read-Utf8 $checksPath | ConvertFrom-Json
$results = @($checks.results)
$fail = [int]$checks.summary.fail
$manual = [int]$checks.summary.manual
$unchecked = [int]$checks.summary.unchecked
$baseCommit = [string]$checks.base_commit

$allFiles = @(Get-AllFiles -Root $Root)
$declared = Expand-Artifacts -Items @($card['artifacts']) -AllFiles $allFiles -Root $Root
$artifacts = @($declared.Files)
if ($declared.Unresolved.Count -gt 0) {
    Write-Host "[warn] unresolved artifacts: $($declared.Unresolved -join ', ')" -ForegroundColor Yellow
}

$hashes = @()
foreach ($a in $artifacts) {
    $hashes += [pscustomobject]@{ Path = $a; Hash = (Get-Sha256 (Join-Path $Root $a)) }
}

$isFinal = ($Checkpoint -eq 'CP-F')
$hold = ($card.ContainsKey('hold') -and $card['hold'].Trim().ToLowerInvariant() -eq 'true')
$machineOk = ($fail -eq 0 -and $unchecked -eq 0)
$autoOk = ($machineOk -and $manual -eq 0)
$approved = $false
$reviewer = 'user'
if ($isFinal) {
    if ($AutoApprove -and $autoOk) {
        $approved = $true
        $reviewer = 'auto (explicit -AutoApprove)'
    }
}
elseif (-not $hold -and $autoOk) {
    $approved = $true
    $reviewer = 'auto (P2)'
}
$decision = if ($approved) { 'approved' } else { '-' }
$now = Get-Date
$reviewedAt = if ($approved) { $now.ToString('yyyy-MM-ddTHH:mm:ss') } else { '-' }
$cpStatus = if ($approved) { 'approved' } else { 'awaiting_review' }
$nextAction = if ($approved -and $isFinal) { 'accept task' } elseif ($approved) { 'continue' } else { 'return to this checkpoint' }
$newCardStatus = Get-CardStatusForCheckpoint -Approved $approved -IsFinal $isFinal

$usage = Get-TaskUsage -Task $Task -ProjectPath $Root
$usageLine = 'n/a'
$usageRows = @()
if ($usage) {
    $inv = [System.Globalization.CultureInfo]::InvariantCulture
    $ratioText = $usage.ratio.ToString($inv)
    $minutesText = ([math]::Round($usage.minutes)).ToString($inv)
    $costText = $usage.cost.ToString('0.00', $inv)
    $usageLine = 'in={0} out={1} cr={2} ratio={3}x min={4}' -f $usage.input, $usage.output, $usage.cache_read, $ratioText, $minutesText
    $usageRows += ('| Sessions | Input | Output | Reasoning | Cache read | Cache/Input | Minutes | Cost |')
    $usageRows += ('|---|---|---|---|---|---|---|---|')
    $usageRows += ('| {0} | {1} | {2} | {3} | {4} | {5}x | {6} | {7} |' -f $usage.sessions, $usage.input, $usage.output, $usage.reasoning, $usage.cache_read, $ratioText, $minutesText, $costText)
}
else {
    $usageRows += @('- token usage not available (opencode CLI or database unavailable)')
}

$diffStat = ''
$gitDiff = Invoke-Git -Root $Root -Arguments @('diff', '--stat') -AllowFail
if ($baseCommit) { $gitDiff = Invoke-Git -Root $Root -Arguments @('diff', '--stat', "$baseCommit..HEAD") -AllowFail }
if ($gitDiff.ExitCode -eq 0) { $diffStat = ($gitDiff.Output -join "`r`n").Trim() }
if (-not $diffStat) { $diffStat = '(no committed diff)' }

$acceptance = @(Get-CardAcceptanceItems -Path $cardPath)
$manualItems = @($results | Where-Object { $_.result -eq 'MANUAL' })

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# $Task ${Checkpoint}: $title")
$lines.Add('')
$lines.Add('| Field | Value |')
$lines.Add('|---|---|')
$lines.Add('| task | ' + $Task + ' |')
$lines.Add('| workflow | ' + $workflow + ' |')
$lines.Add('| bug | ' + $bugValue + ' |')
$lines.Add('| checkpoint | ' + $Checkpoint + ' |')
$lines.Add('| role | ' + $role + ' |')
$lines.Add('| stage | ' + $stage + ' |')
$lines.Add('| artifacts | ' + $cardRels + ' |')
$lines.Add('| status | ' + $cpStatus + ' |')
$lines.Add('| requested_at | ' + $now.ToString('yyyy-MM-ddTHH:mm:ss') + ' |')
$lines.Add('| reviewed_at | ' + $reviewedAt + ' |')
$lines.Add('| reviewer | ' + $reviewer + ' |')
$lines.Add('| decision | ' + $decision + ' |')
$lines.Add('| snapshot_commit | - |')
$lines.Add('| generated_by | stage-done/1 |')
$lines.Add('| checks_file | ' + $checksRel + ' |')
$lines.Add('')
$lines.Add('## Review scope')
$lines.Add('')
$lines.Add("- Stage ``$stage`` acceptance for $Task.")
foreach ($item in $acceptance) { $lines.Add('- ' + $item) }
$lines.Add('')
$lines.Add('## Checks')
$lines.Add('')
$lines.Add('| ID | Check | Result | Detail |')
$lines.Add('|---|---|---|---|')
foreach ($r in $results) {
    $lines.Add(('| {0} | {1} | {2} | {3} |' -f (Format-Cell $r.id), (Format-Cell $r.check), (Format-Cell $r.result), (Format-Cell $r.detail)))
}
$lines.Add('')
$lines.Add("Summary: $($checks.summary.pass) PASS, $fail FAIL, $manual MANUAL, $($checks.summary.not_applicable) N/A, $unchecked UNCHECKED.")
$lines.Add('')
if ($manualItems.Count -gt 0) {
    $lines.Add('## Manual review')
    $lines.Add('')
    foreach ($m in $manualItems) { $lines.Add('- ' + (Format-Cell $m.id) + ': ' + (Format-Cell $m.detail)) }
    $lines.Add('')
}
$lines.Add('## Usage')
$lines.Add('')
foreach ($row in $usageRows) { $lines.Add($row) }
$lines.Add('')
$lines.Add('## Diff stat')
$lines.Add('')
$lines.Add('```')
$lines.Add($diffStat)
$lines.Add('```')
$lines.Add('')
$lines.Add('## User remarks')
$lines.Add('')
$lines.Add('- (user fills; may be empty if artifacts were edited directly)')
$lines.Add('')
$lines.Add('## User edits')
$lines.Add('')
$lines.Add('- none')
$lines.Add('')
$lines.Add('## Role response')
$lines.Add('')
$lines.Add("- Machine checks: $fail FAIL, $unchecked UNCHECKED, $manual MANUAL.")
if ($fail -gt 0) { $lines.Add('- Failed checks: ' + ((@($results | Where-Object { $_.result -eq 'FAIL' }) | ForEach-Object { $_.id }) -join ', ')) }
$lines.Add('')
$lines.Add('## Next action')
$lines.Add('')
$lines.Add('- ' + $nextAction)
$checkpointText = $lines -join "`r`n"

Write-Host ("result: {0} PASS, {1} FAIL, {2} MANUAL, {3} UNCHECKED -> {4}" -f $checks.summary.pass, $fail, $manual, $unchecked, $cpStatus) -ForegroundColor $(if ($fail -gt 0) { 'Red' } elseif ($approved) { 'Green' } else { 'Yellow' })

if ($DryRun) {
    Write-Host "--- checkpoint (dry run) ---" -ForegroundColor Cyan
    Write-Output $checkpointText
    Write-Host "--- planned: board/card status $newCardStatus; usage $usageLine; commit $(-not $NoCommit) ---" -ForegroundColor Cyan
    Remove-Item -LiteralPath $checksPath -Force -ErrorAction SilentlyContinue
    exit 0
}

Write-Utf8NoBom $cpPath $checkpointText

if (-not (Test-Path -LiteralPath $ledgerPath)) {
    $ledger = @(
        "# $Task evidence ledger",
        '',
        'Machine-recorded artifact hashes. The latest row per path wins.',
        '',
        '| Checkpoint | Stage | Artifact | SHA256 | Recorded |',
        '|---|---|---|---|---|'
    ) -join "`r`n"
    Write-Utf8NoBom $ledgerPath ($ledger + "`r`n")
}
$ledgerLines = New-Object System.Collections.Generic.List[string]
foreach ($h in $hashes) {
    $ledgerLines.Add(('| {0} | {1} | {2} | {3} | {4} |' -f $Checkpoint, $stage, $h.Path, $h.Hash, (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')))
}
$ledgerText = (Read-Utf8 $ledgerPath).TrimEnd([char[]]"`r`n") + "`r`n" + ($ledgerLines -join "`r`n") + "`r`n"
Write-Utf8NoBom $ledgerPath $ledgerText

Set-BoardRow -Root $Root -Task $Task -Values @{
    status    = $newCardStatus
    artifacts = $cardRels
    usage     = $usageLine
    commit    = '-'
} | Out-Null

$null = Set-CardField -Path $cardPath -Name 'status' -Value $newCardStatus
$null = Set-CardField -Path $cardPath -Name 'usage' -Value $usageLine
$checksCell = '{0}P/{1}F/{2}M' -f $checks.summary.pass, $fail, $manual
$null = Set-CardCheckpointRow -Path $cardPath -Checkpoint $Checkpoint -Status $cpStatus -ReviewFile $cpRel -Checks $checksCell
$logLine = ('- {0}: {1} {2} ({3}); checks {4} PASS/{5} FAIL/{6} MANUAL/{7} UNCHECKED; usage {8}; reviewer {9}' -f `
        (Get-Date -Format 'yyyy-MM-dd'), $Checkpoint, $cpStatus, $stage, $checks.summary.pass, $fail, $manual, $unchecked, $usageLine, $reviewer)
$cardText = (Read-Utf8 $cardPath).TrimEnd([char[]]"`r`n") + "`r`n" + $logLine + "`r`n"
Write-Utf8NoBom $cardPath $cardText

$activity = Sync-Activity -Root $Root
if ($activity.Rendered) { Write-Host "activity: rendered $($activity.Svg)" -ForegroundColor Green }
else { Write-Host "activity: puml updated, render skipped ($($activity.Reason))" -ForegroundColor Yellow }

if ($NoCommit) {
    Write-Host "commit skipped (-NoCommit)" -ForegroundColor Yellow
    Write-Host "checkpoint: $cpRel"
    exit 0
}

$commitPaths = New-Object System.Collections.Generic.List[string]
foreach ($p in $artifacts) { $commitPaths.Add($p) }
foreach ($p in @('docs/plan.md', $cpRel, $checksRel, $ledgerRel, 'docs/activity.puml', 'docs/activity.svg')) {
    if (Test-Path -LiteralPath (Join-Path $Root $p)) { $commitPaths.Add($p) }
}
$cardRel = ConvertTo-ForwardSlash ((Resolve-Path -LiteralPath $cardPath).Path.Substring($Root.TrimEnd('\').Length + 1))
$commitPaths.Add($cardRel)
$commitPaths = @($commitPaths | Sort-Object -Unique)

$null = Invoke-Git -Root $Root -Arguments (@('add', '--') + $commitPaths)
$staged = Invoke-Git -Root $Root -Arguments @('diff', '--cached', '--name-only') -AllowFail
if ($staged.Output.Count -eq 0) {
    Write-Host "nothing to commit" -ForegroundColor Yellow
    Write-Host "checkpoint: $cpRel"
    exit 0
}
$message = "$Task`: checkpoint $Checkpoint ($stage)"
$null = Invoke-Git -Root $Root -Arguments @('commit', '-m', $message)
$head = Invoke-Git -Root $Root -Arguments @('rev-parse', '--short', 'HEAD')
$hash = ([string]$head.Output[0]).Trim()

$cpText = Read-Utf8 $cpPath
$cpText = [regex]::Replace($cpText, '(?m)^\|\s*snapshot_commit\s*\|\s*.*?\s*\|\s*$', "| snapshot_commit | $hash |")
Write-Utf8NoBom $cpPath $cpText
Set-BoardRow -Root $Root -Task $Task -Values @{ commit = $hash } | Out-Null
$null = Set-CardField -Path $cardPath -Name 'commit' -Value $hash
$cardText = (Read-Utf8 $cardPath).TrimEnd([char[]]"`r`n") + "`r`n" + "- $($hash): $Checkpoint snapshot" + "`r`n"
Write-Utf8NoBom $cardPath $cardText
$null = Invoke-Git -Root $Root -Arguments (@('add', '--') + @($cpRel, 'docs/plan.md', $cardRel))
$null = Invoke-Git -Root $Root -Arguments @('commit', '-m', "$Task`: record $Checkpoint snapshot $hash")

Write-Host ""
Write-Host "checkpoint: $cpRel"
Write-Host "status: $newCardStatus ($cpStatus)"
Write-Host "commit: $hash"
Write-Host "next: $nextAction"
exit 0
