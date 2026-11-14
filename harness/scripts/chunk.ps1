#requires -Version 5.1
<#
.SYNOPSIS
Manage the harness chunk ledger (docs/chunks/T-XXX.json).

.DESCRIPTION
The ledger is the single source of truth for per-chunk progress. Planning fields
(title, owns, inputs, acceptance) are written at plan time; machine fields
(state, attempts, produced.sha256, usage, base_commit) are written only here.

.Actions
  init     create the ledger skeleton and docs/chunks/T-XXX/
  add      append one chunk
  plan     merge a plan file (array of chunks or {"chunks":[...]})
  claim    pending|failed|blocked -> in_progress
  complete in_progress -> done, record produced sha256
  fail     in_progress -> failed|blocked, record the reason
  list     list chunks
  show     show one chunk
  status   one-line progress for the task
  usage    attribute session usage to chunks (from the opencode database)
  verify   run chunk-validate.py

.EXAMPLE
.\chunk.ps1 init -Task T-008
.\chunk.ps1 add -Task T-008 -Id C4a -Stage I-01 -Role coder -Title "API-001" -Owns "backend/src/main/java/**/api/**" -Inputs "docs/architecture/contracts-*.md"
.\chunk.ps1 claim -Task T-008 -Id C4a
.\chunk.ps1 complete -Task T-008 -Id C4a -Produced "backend/src/main/java/x/Api.java"
.\chunk.ps1 status -Task T-008
.\chunk.ps1 verify -Task T-008
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('init', 'add', 'plan', 'claim', 'complete', 'fail', 'list', 'show', 'status', 'usage', 'verify')]
    [string]$Action,
    [Parameter(Mandatory = $true)][string]$Task,
    [string]$Id = '',
    [string]$Parent = '',
    [string]$Stage = '',
    [string]$Role = '',
    [string]$Title = '',
    [string[]]$Owns = @(),
    [string[]]$Inputs = @(),
    [string[]]$Acceptance = @(),
    [string]$Brief = '',
    [string[]]$Produced = @(),
    [string]$Note = '',
    [string]$Issue = '',
    [string]$File = '',
    [int]$In = 0,
    [int]$Out = 0,
    [int]$CacheRead = 0,
    [int]$Minutes = 0,
    [switch]$Blocked,
    [switch]$Json,
    [switch]$Force,
    [string]$Root = ''
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "harness-lib.ps1")

if (-not $Root) { $Root = Get-HarnessRoot }
$Root = (Resolve-Path -LiteralPath $Root).Path
$ledgerRel = "docs/chunks/$Task.json"
$ledgerPath = Join-Path $Root ($ledgerRel -replace '/', '\')
$chunkDir = Join-Path $Root ("docs\chunks\$Task")

function Read-Ledger {
    if (-not (Test-Path -LiteralPath $ledgerPath)) {
        throw "ledger not found: $ledgerRel (run: chunk.ps1 init -Task $Task)"
    }
    $raw = Read-Utf8 $ledgerPath
    $data = $raw | ConvertFrom-Json
    if ($null -eq $data.chunks) { $data | Add-Member -NotePropertyName chunks -NotePropertyValue @() -Force }
    $data
}

function Write-Ledger {
    param($Data)
    $Data | Add-Member -NotePropertyName updated -NotePropertyValue (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss') -Force
    Write-Utf8NoBom $ledgerPath (($Data | ConvertTo-Json -Depth 100) + "`n")
}

function Get-Chunk {
    param($Data, [string]$ChunkId)
    $found = @($Data.chunks | Where-Object { $_.id -eq $ChunkId })
    if ($found.Count -eq 0) { throw "chunk '$ChunkId' not found in $ledgerRel" }
    $found[0]
}

function Get-HeadHash {
    $r = Invoke-Git -Root $Root -Arguments @('rev-parse', '--short', 'HEAD') -AllowFail
    if ($r.ExitCode -eq 0 -and $r.Output.Count -gt 0) { ([string]$r.Output[0]).Trim() } else { '' }
}

function New-ChunkRecord {
    param([string]$ChunkId)
    $parentValue = $null
    if ($Parent) { $parentValue = $Parent }
    $depth = 1
    $stageValue = $Stage
    $roleValue = $Role
    if ($parentValue) {
        $data = Read-Ledger
        $parentChunk = Get-Chunk -Data $data -ChunkId $parentValue
        $depth = [int]$parentChunk.depth + 1
        if (-not $stageValue) { $stageValue = [string]$parentChunk.stage }
        if (-not $roleValue) { $roleValue = [string]$parentChunk.role }
    }
    if (-not $stageValue) { throw "-Stage is required for a top-level chunk" }
    if (-not $roleValue) { throw "-Role is required for a top-level chunk" }
    if ($depth -gt 3) { throw "depth $depth exceeds the ceiling 3; split the parent differently" }
    $briefRel = $Brief
    if (-not $briefRel) { $briefRel = "docs/chunks/$Task/$ChunkId.brief.md" }
    [ordered]@{
        id         = $ChunkId
        parent     = $parentValue
        stage      = $stageValue
        role       = $roleValue
        depth      = $depth
        title      = $Title
        state      = 'pending'
        owns       = @($Owns)
        inputs     = @($Inputs)
        brief      = $briefRel
        acceptance = @($Acceptance)
        produced   = @()
        base_commit = (Get-HeadHash)
        attempts   = 0
        usage      = [ordered]@{ in = 0; out = 0; cr = 0; min = 0 }
        issues     = @()
        notes      = @()
        started    = $null
        finished   = $null
    }
}

function Assert-LedgerId {
    if ($Task -notmatch '^T-\d{3,}$') { throw "Task must look like T-XXX, got '$Task'" }
}

Assert-LedgerId

switch ($Action) {
    'init' {
        if ((Test-Path -LiteralPath $ledgerPath) -and -not $Force) {
            Write-Host "[skip] $ledgerRel already exists; use -Force to recreate" -ForegroundColor Yellow
            exit 0
        }
        if (-not (Test-Path -LiteralPath $chunkDir)) { New-Item -ItemType Directory -Force -Path $chunkDir | Out-Null }
        $ledger = [ordered]@{
            task    = $Task
            version = 1
            updated = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
            budget  = [ordered]@{
                max_write_kb     = 12
                max_session_kb   = 40
                context_stop_pct = 65
                max_turns        = 40
                max_input_tokens = 60000
                max_wall_min     = 45
            }
            chunks  = @()
        }
        Write-Utf8NoBom $ledgerPath (($ledger | ConvertTo-Json -Depth 100) + "`n")
        Write-Host "ledger: $ledgerRel"
        Write-Host "next: chunk.ps1 add|plan -Task $Task"
        exit 0
    }
    'add' {
        if (-not $Id) { throw "-Id is required" }
        $data = Read-Ledger
        if (@($data.chunks | Where-Object { $_.id -eq $Id }).Count -gt 0) { throw "chunk '$Id' already exists" }
        $record = New-ChunkRecord -ChunkId $Id
        $data.chunks = @($data.chunks) + @([pscustomobject]$record)
        Write-Ledger $data
        Write-Host "added $Id (depth $($record.depth), $($record.role)/$($record.stage))"
        exit 0
    }
    'plan' {
        if (-not $File) { throw "-File is required (JSON array of chunks or {chunks:[...]})" }
        $path = if ([System.IO.Path]::IsPathRooted($File)) { $File } else { Join-Path $Root $File }
        $incoming = (Read-Utf8 $path) | ConvertFrom-Json
        $items = if ($incoming -is [array]) { @($incoming) } else { @($incoming.chunks) }
        $data = Read-Ledger
        $existing = @($data.chunks | ForEach-Object { $_.id })
        $added = 0
        foreach ($item in $items) {
            if (-not $item.id) { throw "every planned chunk needs an id" }
            if ($existing -contains $item.id) { throw "chunk '$($item.id)' already exists" }
            $parentValue = $null
            if ($item.parent) { $parentValue = [string]$item.parent }
            $depth = 1
            $stageValue = [string]$item.stage
            $roleValue = [string]$item.role
            if ($parentValue) {
                $parentChunk = Get-Chunk -Data $data -ChunkId $parentValue
                $depth = [int]$parentChunk.depth + 1
                if (-not $stageValue) { $stageValue = [string]$parentChunk.stage }
                if (-not $roleValue) { $roleValue = [string]$parentChunk.role }
            }
            if ($depth -gt 3) { throw "chunk '$($item.id)' would exceed the depth ceiling 3" }
            $briefRel = [string]$item.brief
            if (-not $briefRel) { $briefRel = "docs/chunks/$Task/$($item.id).brief.md" }
            $record = [ordered]@{
                id          = [string]$item.id
                parent      = $parentValue
                stage       = $stageValue
                role        = $roleValue
                depth       = $depth
                title       = [string]$item.title
                state       = 'pending'
                owns        = @($item.owns)
                inputs      = @($item.inputs)
                brief       = $briefRel
                acceptance  = @($item.acceptance)
                produced    = @()
                base_commit = (Get-HeadHash)
                attempts    = 0
                usage       = [ordered]@{ in = 0; out = 0; cr = 0; min = 0 }
                issues      = @()
                notes       = @()
                started     = $null
                finished    = $null
            }
            $data.chunks = @($data.chunks) + @([pscustomobject]$record)
            $existing += $record.id
            $added++
        }
        Write-Ledger $data
        Write-Host "planned $added chunk(s); total $(@($data.chunks).Count)"
        exit 0
    }
    'claim' {
        if (-not $Id) { throw "-Id is required" }
        $data = Read-Ledger
        $chunk = Get-Chunk -Data $data -ChunkId $Id
        if ($chunk.state -eq 'in_progress' -and -not $Force) {
            Write-Host "[skip] $Id is already in_progress; use -Force to restart" -ForegroundColor Yellow
            exit 0
        }
        if ($chunk.state -eq 'done' -and -not $Force) { throw "chunk '$Id' is done; use -Force to reopen" }
        $chunk.state = 'in_progress'
        $chunk.attempts = [int]$chunk.attempts + 1
        $chunk.started = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        $chunk.finished = $null
        Write-Ledger $data
        Write-Host "claimed $Id (attempt $($chunk.attempts), depth $($chunk.depth))"
        exit 0
    }
    'complete' {
        if (-not $Id) { throw "-Id is required" }
        $data = Read-Ledger
        $chunk = Get-Chunk -Data $data -ChunkId $Id
        if ($chunk.state -eq 'done' -and -not $Force) {
            Write-Host "[skip] $Id is already done" -ForegroundColor Yellow
            exit 0
        }
        $records = @()
        foreach ($raw in $Produced) {
            foreach ($piece in ([string]$raw).Split(',')) {
                $rel = ConvertTo-ForwardSlash ($piece.Trim())
                if (-not $rel) { continue }
                $abs = Join-Path $Root ($rel -replace '/', '\')
                if (-not (Test-Path -LiteralPath $abs -PathType Leaf)) {
                    throw "produced file not found: $rel"
                }
                $records += [ordered]@{ path = $rel; sha256 = (Get-Sha256 $abs) }
            }
        }
        if ($records.Count -eq 0 -and @($chunk.owns).Count -gt 0) {
            throw "-Produced is required: a chunk with an owns set must record what it produced"
        }
        $chunk.produced = @($records)
        $chunk.state = 'done'
        $chunk.finished = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        $chunk.usage = [ordered]@{ in = $In; out = $Out; cr = $CacheRead; min = $Minutes }
        if ($Note) { $chunk.notes = @($chunk.notes) + $Note }
        Write-Ledger $data
        Write-Host "completed ${Id}: $($records.Count) produced file(s)"
        exit 0
    }
    'fail' {
        if (-not $Id) { throw "-Id is required" }
        $data = Read-Ledger
        $chunk = Get-Chunk -Data $data -ChunkId $Id
        $chunk.state = if ($Blocked) { 'blocked' } else { 'failed' }
        if ($Note) { $chunk.notes = @($chunk.notes) + $Note }
        if ($Issue) { $chunk.issues = @($chunk.issues) + $Issue }
        if ($Blocked -and -not $Issue) { throw "a blocked chunk needs -Issue I-YYYYMMDD-HHMMSS" }
        Write-Ledger $data
        Write-Host "marked $Id as $($chunk.state)"
        exit 0
    }
    'list' {
        $data = Read-Ledger
        if ($Json) { @($data.chunks) | ConvertTo-Json -Depth 100; exit 0 }
        foreach ($c in $data.chunks) {
            Write-Host ("{0,-10} d{1} {2,-12} {3,-11} {4}" -f $c.id, $c.depth, $c.state, $c.role, $c.title)
        }
        exit 0
    }
    'show' {
        if (-not $Id) { throw "-Id is required" }
        $data = Read-Ledger
        $chunk = Get-Chunk -Data $data -ChunkId $Id
        $chunk | ConvertTo-Json -Depth 100
        exit 0
    }
    'status' {
        $data = Read-Ledger
        $all = @($data.chunks)
        $done = @($all | Where-Object { $_.state -eq 'done' })
        $active = @($all | Where-Object { $_.state -eq 'in_progress' })
        $failed = @($all | Where-Object { $_.state -in @('failed', 'blocked') })
        $next = @($all | Where-Object { $_.state -eq 'pending' } | Select-Object -First 1)
        $line = '{0}: {1}/{2} done' -f $Task, $done.Count, $all.Count
        if ($active.Count -gt 0) { $line += '; active ' + (($active | ForEach-Object { $_.id }) -join ',') }
        if ($failed.Count -gt 0) { $line += '; failed ' + (($failed | ForEach-Object { $_.id }) -join ',') }
        if ($next) { $line += '; next ' + $next.id } else { $line += '; no pending chunk' }
        Write-Host $line
        exit 0
    }
    'usage' {
        $data = Read-Ledger
        $rows = @(Get-ChunkUsage -Task $Task -ProjectPath $Root)
        if ($null -eq $rows) {
            Write-Host "[warn] opencode CLI or session database is unavailable; usage not collected" -ForegroundColor Yellow
            exit 0
        }
        foreach ($c in $data.chunks) {
            $match = @($rows | Where-Object { $_.chunk -eq $c.id }) | Select-Object -First 1
            $inV = 0; $outV = 0; $crV = 0; $minV = 0
            if ($match) {
                $inV = [int]$match.input
                $outV = [int]$match.output
                $crV = [int]$match.cache_read
                $minV = [int][math]::Round($match.minutes)
            }
            $c.usage = [ordered]@{ in = $inV; out = $outV; cr = $crV; min = $minV }
            $text = if ($match) { "in=$inV out=$outV cr=$crV min=$minV ratio=$($match.ratio)x" } else { 'no sessions' }
            Write-Host ('{0,-10} {1}' -f $c.id, $text)
        }
        Write-Ledger $data
        exit 0
    }
    'verify' {
        $py = Get-Command python -ErrorAction SilentlyContinue
        if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
        if (-not $py) { throw "python not found; cannot run chunk-validate.py" }
        & $py.Source (Join-Path $PSScriptRoot 'chunk-validate.py') $ledgerPath --root $Root
        exit $LASTEXITCODE
    }
}
