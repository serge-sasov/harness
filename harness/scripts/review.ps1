#requires -Version 5.1
<#
.SYNOPSIS
  Read-only checkpoint, batch-group, and approval review for harness.

.DESCRIPTION
  Prints pending checkpoints, task review packets, group status, or statistics.
  No board, card, or checkpoint state is changed. Use approve.ps1 for decisions.

.EXAMPLE
  .\review.ps1 -Pending
  .\review.ps1 -Task T-005
  .\review.ps1 -Group RG-BUILD
  .\review.ps1 -Stats -Json
#>
[CmdletBinding()]
param(
    [string]$Root = '',
    [string]$Task = '',
    [string]$Checkpoint = '',
    [string]$Group = '',
    [switch]$Pending,
    [switch]$Stats,
    [switch]$Json,
    [string]$OutFile = ''
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "harness-lib.ps1")

if (-not $Root) { $Root = Get-HarnessRoot }
$Root = (Resolve-Path -LiteralPath $Root).Path
if ($Checkpoint -and -not $Task) { throw "-Checkpoint requires -Task" }
$policy = Get-RiskPolicy -Root $Root
$reviewGroups = Get-ReviewGroups -Root $Root
$cards = @(Get-CardEntries -Root $Root)
$open = @(Get-OpenCheckpoints -Root $Root)

$lines = New-Object System.Collections.Generic.List[string]
$payload = [ordered]@{
    root                = $Root
    policy_mode         = [string]$policy.Mode
    policy_exists       = [bool]$policy.Exists
    review_groups_exist = [bool]$reviewGroups.Exists
}

function Add-Line {
    param([string]$Text = '')
    $lines.Add($Text)
}

function Format-Wait {
    param($Hours)
    if ($null -eq $Hours) { return '-' }
    ('{0:N1}h' -f [double]$Hours)
}

function Get-CardValue {
    param($Card, [string]$Name)
    [string](Get-JsonPropertyValue $Card $Name)
}

function Get-CheckpointStats {
    param([string]$CheckpointRoot)
    $dir = Join-Path $CheckpointRoot 'docs\checkpoints'
    $result = [ordered]@{
        total = 0; awaiting = 0; approved = 0; changes_requested = 0; rejected = 0
        auto = 0; human = 0; critical = 0; high = 0; medium = 0; low = 0
        average_wait_hours = $null
    }
    if (-not (Test-Path -LiteralPath $dir)) { return [pscustomobject]$result }
    $waits = @()
    foreach ($file in @(Get-ChildItem -LiteralPath $dir -Filter 'T-*-CP-*.md' -File -ErrorAction SilentlyContinue)) {
        $fields = Get-CheckpointFields -Path $file.FullName
        $status = Get-CardValue $fields 'status'
        $reviewer = Get-CardValue $fields 'reviewer'
        $tier = (Get-CardValue $fields 'risk_tier').ToLowerInvariant()
        $result.total++
        switch ($status) {
            'awaiting_review' { $result.awaiting++ }
            'approved' { $result.approved++ }
            'changes_requested' { $result.changes_requested++ }
            'rejected' { $result.rejected++ }
        }
        if ($status -ne 'awaiting_review') {
            if ($reviewer -like 'auto*') { $result.auto++ } elseif ($reviewer) { $result.human++ }
        }
        if ($result.Contains($tier)) { $result[$tier]++ }
        if ($status -eq 'awaiting_review') {
            $requested = Get-CardValue $fields 'requested_at'
            if ($requested -and $requested -ne '-') {
                try {
                    $dt = [datetime]::Parse($requested, [System.Globalization.CultureInfo]::InvariantCulture)
                    $waits += ((Get-Date) - $dt).TotalHours
                }
                catch { }
            }
        }
    }
    if ($waits.Count -gt 0) { $result.average_wait_hours = [math]::Round((($waits | Measure-Object -Average).Average), 1) }
    [pscustomobject]$result
}

if ($Stats) {
    $statsResult = Get-CheckpointStats -CheckpointRoot $Root
    $payload['stats'] = $statsResult
    Add-Line '# Checkpoint statistics'
    Add-Line ''
    Add-Line '| Metric | Value |'
    Add-Line '|---|---|'
    Add-Line ("| Total | {0} |" -f $statsResult.total)
    Add-Line ("| Awaiting review | {0} |" -f $statsResult.awaiting)
    Add-Line ("| Approved | {0} |" -f $statsResult.approved)
    Add-Line ("| Changes requested | {0} |" -f $statsResult.changes_requested)
    Add-Line ("| Rejected | {0} |" -f $statsResult.rejected)
    Add-Line ("| Auto decisions | {0} |" -f $statsResult.auto)
    Add-Line ("| Human decisions | {0} |" -f $statsResult.human)
    Add-Line ("| Critical / high / medium / low | {0} / {1} / {2} / {3} |" -f $statsResult.critical, $statsResult.high, $statsResult.medium, $statsResult.low)
    Add-Line ("| Average open wait | {0} |" -f (Format-Wait $statsResult.average_wait_hours))
}
elseif ($Group) {
    $groupDef = Get-ReviewGroupById -Config $reviewGroups -Id $Group
    if (-not $groupDef) { throw "review group '$Group' not found" }
    $stages = @((Get-JsonPropertyValue $groupDef 'stages'))
    $groupCards = @($cards | Where-Object {
            $cardStages = @(((Get-CardValue $_ 'stage') -split '[/,]') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            @($cardStages | Where-Object { $stages -contains $_ }).Count -gt 0
        })
    $groupOpen = @($open | Where-Object { $_.ReviewGroup -eq $Group })
    $payload['group'] = [ordered]@{
        id              = [string](Get-JsonPropertyValue $groupDef 'id')
        title           = [string](Get-JsonPropertyValue $groupDef 'title')
        stages          = $stages
        gate_stage      = [string](Get-JsonPropertyValue $groupDef 'gate_stage')
        gate_checkpoint = [string](Get-JsonPropertyValue $groupDef 'gate_checkpoint')
        open            = $groupOpen
    }
    Add-Line ("# Review group {0}: {1}" -f (Get-JsonPropertyValue $groupDef 'id'), (Get-JsonPropertyValue $groupDef 'title'))
    Add-Line ''
    Add-Line ("- Stages: {0}" -f ($stages -join ', '))
    Add-Line ("- Gate: {0} {1}" -f (Get-JsonPropertyValue $groupDef 'gate_stage'), (Get-JsonPropertyValue $groupDef 'gate_checkpoint'))
    Add-Line ''
    Add-Line '| Task | Stage | Role | Status | Card |'
    Add-Line '|---|---|---|---|---|'
    foreach ($card in $groupCards) {
        Add-Line ("| {0} | {1} | {2} | {3} | {4} |" -f (Get-CardValue $card 'id'), (Get-CardValue $card 'stage'), (Get-CardValue $card 'role'), (Get-CardValue $card 'status'), (Get-CardValue $card 'path'))
    }
    Add-Line ''
    if ($groupOpen.Count -eq 0) { Add-Line 'No open gate checkpoint for this group.' }
    else {
        Add-Line '## Open checkpoints'
        Add-Line ''
        foreach ($row in $groupOpen) {
            Add-Line ("- {0} {1}: {2}; risk {3}; waits {4}; {5}" -f $row.Task, $row.Checkpoint, $row.Path, $row.RiskTier, (Format-Wait $row.WaitHours), $row.ChecksFile)
        }
    }
}
elseif ($Task) {
    $cardPath = Get-CardFile -Root $Root -Task $Task
    if (-not $cardPath) { throw "task card not found for $Task" }
    $card = Get-CardFields -Path $cardPath
    $rows = @(Get-CardCheckpointRows -Path $cardPath)
    $payload['task'] = [ordered]@{
        id       = $Task
        path     = $cardPath
        fields   = $card
        checkpoints = $rows
    }
    Add-Line "# Review task $Task"
    Add-Line ''
    Add-Line ("- Title: {0}" -f (Get-CardValue $card 'title'))
    Add-Line ("- Workflow/stage: {0} / {1}" -f (Get-CardValue $card 'workflow'), (Get-CardValue $card 'stage'))
    Add-Line ("- Role: {0}" -f (Get-CardValue $card 'role'))
    Add-Line ("- Status: {0}" -f (Get-CardValue $card 'status'))
    Add-Line ("- Hold: {0}; risk override: {1}; review mode: {2}" -f (Get-CardValue $card 'hold'), (Get-CardValue $card 'risk_tier'), (Get-CardValue $card 'review_mode'))
    Add-Line ("- Artifacts: {0}" -f (Get-CardValue $card 'artifacts'))
    Add-Line ''
    Add-Line '| Checkpoint | Stage | Status | Checks | Review file |'
    Add-Line '|---|---|---|---|---|'
    foreach ($row in $rows) {
        Add-Line ("| {0} | {1} | {2} | {3} | {4} |" -f (Get-CardValue $row 'id'), (Get-CardValue $row 'stage'), (Get-CardValue $row 'status'), (Get-CardValue $row 'checks'), (Get-CardValue $row 'review file'))
    }
    if ($Checkpoint) {
        $cpPath = Get-CheckpointFile -Root $Root -Task $Task -Checkpoint $Checkpoint
        if (-not $cpPath) { throw "checkpoint $Task $Checkpoint not found" }
        Add-Line ''
        Add-Line ("## $Task $Checkpoint")
        Add-Line ''
        Add-Line '```markdown'
        Add-Line (Read-Utf8 $cpPath)
        Add-Line '```'
        Add-Line ''
        Add-Line 'Approve with:'
        Add-Line ''
        Add-Line ('`powershell -NoProfile -File "{0}" -Task {1} -Checkpoint {2} -Decision approved`' -f (Join-Path $PSScriptRoot 'approve.ps1'), $Task, $Checkpoint)
    }
    else {
        $taskOpen = @($open | Where-Object { $_.Task -eq $Task })
        Add-Line ''
        if ($taskOpen.Count -eq 0) { Add-Line 'No open checkpoint for this task.' }
        else {
            Add-Line '## Open checkpoints'
            Add-Line ''
            foreach ($row in $taskOpen) { Add-Line ("- {0}: {1}; risk {2}; review {3}" -f $row.Checkpoint, $row.Stage, $row.RiskTier, $row.Path) }
        }
    }
}
else {
    $rows = @($open)
    $payload['pending'] = $rows
    Add-Line '# Pending checkpoint reviews'
    Add-Line ''
    if ($rows.Count -eq 0) {
        Add-Line 'No checkpoints are awaiting review.'
    }
    else {
        Add-Line '| Task | Stage | Checkpoint | Risk | Group | Gate | Requested | Wait | Checks |'
        Add-Line '|---|---|---|---|---|---|---|---|---|'
        foreach ($row in $rows) {
            Add-Line ("| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8}P/{9}F/{10}M/{11}U |" -f `
                    $row.Task, $row.Stage, $row.Checkpoint, $row.RiskTier, $row.ReviewGroup, $row.Gate, $row.RequestedAt, (Format-Wait $row.WaitHours), $row.Pass, $row.Fail, $row.Manual, $row.Unchecked)
        }
        Add-Line ''
        Add-Line ('Use `{0} -Task T-XXX -Checkpoint CP-N` for a packet.' -f (Join-Path $PSScriptRoot 'review.ps1'))
    }
}

$text = ($lines -join "`r`n").TrimEnd() + "`r`n"
if ($Json) {
    $text = (($payload | ConvertTo-Json -Depth 12) + "`r`n")
}
if ($OutFile) {
    $outPath = if ([System.IO.Path]::IsPathRooted($OutFile)) { $OutFile } else { Join-Path $Root $OutFile }
    Write-Utf8NoBom $outPath $text
    Write-Host "review: $outPath"
}
else {
    Write-Output $text
}
