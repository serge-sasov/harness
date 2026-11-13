#requires -Version 5.1
<#
.SYNOPSIS
Reconcile docs/plan.md and task cards with checkpoint files.

.DESCRIPTION
Derives the authoritative status from checkpoint files (CP-F approved -> done;
any awaiting_review -> awaiting_review), updates board/card fields and re-renders
the derived activity diagram. Read-only with -DryRun.

.EXAMPLE
.\board-update.ps1 -All -DryRun
.\board-update.ps1 -Task T-005
#>
[CmdletBinding()]
param(
    [string]$Task,
    [switch]$All,
    [string]$Root = '',
    [switch]$SyncFields,
    [switch]$DryRun,
    [switch]$NoCommit,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "harness-lib.ps1")

if (-not $Root) { $Root = Get-HarnessRoot }
$Root = (Resolve-Path -LiteralPath $Root).Path
if (-not $Task -and -not $All) { throw "Specify -Task T-XXX or -All" }

$board = Get-BoardTable -Root $Root
if ($board.Rows.Count -eq 0) { throw "Board not found or empty: $($board.Path)" }
$active = @($board.Rows | Where-Object { $_.status -in @('in_progress', 'awaiting_review') })
if ($active.Count -gt 0 -and -not $Force -and -not $DryRun) {
    throw "board update is forbidden while a task is active: $(($active | ForEach-Object { $_.id }) -join ', '); use -DryRun or stop the task first"
}

$targets = if ($All) { @($board.Rows | ForEach-Object { $_.id }) } else { @($Task) }
$changes = @()

foreach ($id in $targets) {
    $row = $board.Rows | Where-Object { $_.id -eq $id } | Select-Object -First 1
    if (-not $row) {
        Write-Host "[warn] $id is not on the board; skipped" -ForegroundColor Yellow
        continue
    }
    $cardPath = Get-CardFile -Root $Root -Task $id
    if (-not $cardPath) {
        Write-Host "[warn] $id has no card; skipped" -ForegroundColor Yellow
        continue
    }
    $card = Get-CardFields -Path $cardPath
    $cardStatus = if ($card.ContainsKey('status')) { $card['status'].Trim() } else { 'pending' }

    $cpFiles = @(Get-ChildItem -LiteralPath (Join-Path $Root 'docs\checkpoints') -Filter "$id-CP-*.md" -File -ErrorAction SilentlyContinue)
    $cpStatuses = @()
    $cpFApproved = $false
    foreach ($f in $cpFiles) {
        $status = Get-CheckpointField -Path $f.FullName -Name 'status'
        if ($status) { $cpStatuses += $status.ToLowerInvariant() }
        if ($f.Name -match 'CP-F' -and $status -eq 'approved') { $cpFApproved = $true }
    }

    $derived = $cardStatus
    if ($cardStatus -notin @('blocked', 'failed')) {
        if ($cpFApproved) { $derived = 'done' }
        elseif ($cpStatuses -contains 'awaiting_review') { $derived = 'awaiting_review' }
        elseif ($cpStatuses -contains 'changes_requested') { $derived = 'in_progress' }
        elseif ($cardStatus -eq 'awaiting_review' -and $cpStatuses.Count -eq 0) { $derived = 'in_progress' }
    }

    $cardArtifacts = if ($card.ContainsKey('artifacts')) { (($card['artifacts'] -replace '`', '').Trim()) } else { '-' }
    $cardCommit = if ($card.ContainsKey('commit')) { (($card['commit'] -replace '`', '').Trim()) } else { '-' }
    if (-not $cardCommit) { $cardCommit = '-' }

    $newValues = @{}
    if ($row.status -ne $derived) { $newValues['status'] = $derived }
    if ($SyncFields) {
        if ($row.artifacts -ne $cardArtifacts) { $newValues['artifacts'] = $cardArtifacts }
        if ($row.commit -ne $cardCommit) { $newValues['commit'] = $cardCommit }
    }

    if ($newValues.Count -eq 0) { continue }

    $summary = ($newValues.Keys | Sort-Object | ForEach-Object { "$_=$($newValues[$_])" }) -join ', '
    $changes += [pscustomobject]@{ Task = $id; Changes = $summary; Card = $cardPath; Status = $derived }
    Write-Host ("[{0}] {1}: {2}" -f $(if ($DryRun) { 'dry' } else { 'set' }), $id, $summary)
    if (-not $DryRun) {
        Set-BoardRow -Root $Root -Task $id -Values $newValues | Out-Null
        if ($derived -ne $cardStatus) {
            $null = Set-CardField -Path $cardPath -Name 'status' -Value $derived
        }
    }
}

if ($changes.Count -eq 0) {
    Write-Host "board is consistent; no changes" -ForegroundColor Green
    exit 0
}

if ($DryRun) {
    Write-Host "dry run: $($changes.Count) task(s) would change" -ForegroundColor Cyan
    exit 0
}

$activity = Sync-Activity -Root $Root
if ($activity.Rendered) { Write-Host "activity: rendered $($activity.Svg)" -ForegroundColor Green }
else { Write-Host "activity: puml updated, render skipped ($($activity.Reason))" -ForegroundColor Yellow }

if ($NoCommit) { exit 0 }

$paths = New-Object System.Collections.Generic.List[string]
$paths.Add('docs/plan.md')
foreach ($c in $changes) { $paths.Add((ConvertTo-ForwardSlash ($c.Card.Substring($Root.TrimEnd('\').Length + 1)))) }
foreach ($p in @('docs/activity.puml', 'docs/activity.svg')) {
    if (Test-Path -LiteralPath (Join-Path $Root $p)) { $paths.Add($p) }
}
$paths = @($paths | Sort-Object -Unique)
$null = Invoke-Git -Root $Root -Arguments (@('add', '--') + $paths)
$staged = Invoke-Git -Root $Root -Arguments @('diff', '--cached', '--name-only') -AllowFail
if ($staged.Output.Count -eq 0) { exit 0 }
$scope = if ($All) { 'all' } else { $Task }
$null = Invoke-Git -Root $Root -Arguments @('commit', '-m', "chore: board update ($scope)")
$head = Invoke-Git -Root $Root -Arguments @('rev-parse', '--short', 'HEAD')
Write-Host "commit: $(([string]$head.Output[0]).Trim())"
exit 0
