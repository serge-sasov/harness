#requires -Version 5.1
<#
.SYNOPSIS
Token usage per harness task from the opencode session database.

.DESCRIPTION
Attributes child sessions to the root task from the session title, then reports
input/output/reasoning/cache-read tokens, cache/input ratio, minutes, and cost.
Non-blocking: when opencode or the database is unavailable, exits 0 with a
warning.

.EXAMPLE
.\measure-tokens.ps1
.\measure-tokens.ps1 -Task T-005 -Json
.\measure-tokens.ps1 -Task T-005 -OutFile docs/metrics/tokens.md -Markdown
#>
[CmdletBinding()]
param(
    [string]$Task,
    [string]$Chunk = '',
    [switch]$ByChunk,
    [string]$ProjectPath = '',
    [string]$Root = '',
    [int]$Days = 0,
    [switch]$Json,
    [string]$OutFile,
    [switch]$Markdown
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "harness-lib.ps1")

if (-not $Root) { $Root = Get-HarnessRoot }
$Root = (Resolve-Path -LiteralPath $Root).Path
if (-not $ProjectPath) { $ProjectPath = $Root }

if ($ByChunk) {
    $chunkRows = @(Get-ChunkUsage -Task $Task -ProjectPath $ProjectPath -Days $Days)
    if ($null -eq $chunkRows) {
        Write-Host "[warn] opencode CLI or session database is unavailable; per-chunk usage not collected" -ForegroundColor Yellow
        exit 0
    }
    if ($Chunk) { $chunkRows = @($chunkRows | Where-Object { $_.chunk -eq $Chunk }) }
    if ($chunkRows.Count -eq 0) {
        Write-Host "[warn] no sessions with a T-XXX chunk id in the title" -ForegroundColor Yellow
        exit 0
    }
    $inv = [System.Globalization.CultureInfo]::InvariantCulture
    if ($Json) { $chunkRows | ConvertTo-Json -Depth 4; exit 0 }
    if ($Markdown -or $OutFile) {
        $sb = New-Object System.Text.StringBuilder
        [void]$sb.AppendLine('# Token usage by chunk')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("Project: ``$ProjectPath``")
        [void]$sb.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')")
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| Task | Chunk | Sessions | Input | Output | Reasoning | Cache read | Cache/Input | Minutes | Cost |')
        [void]$sb.AppendLine('|---|---|---|---|---|---|---|---|---|---|')
        foreach ($r in $chunkRows) {
            [void]$sb.AppendLine(('| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7}x | {8} | ${9} |' -f `
                        $r.task, $r.chunk, $r.sessions, $r.input, $r.output, $r.reasoning, $r.cache_read, `
                        $r.ratio.ToString($inv), ([math]::Round($r.minutes)).ToString($inv), $r.cost.ToString('0.00', $inv)))
        }
        $text = $sb.ToString()
        if ($OutFile) {
            $path = if ([System.IO.Path]::IsPathRooted($OutFile)) { $OutFile } else { Join-Path $Root $OutFile }
            Write-Utf8NoBom $path $text
            Write-Host "markdown: $path"
        }
        else { Write-Output $text }
        exit 0
    }
    foreach ($r in $chunkRows) {
        Write-Host ("{0} {1,-8} sessions={2,-3} in={3,-9} out={4,-8} ratio={5,5}x min={6,6} cost={7}" -f `
                $r.task, $r.chunk, $r.sessions, $r.input, $r.output, `
                $r.ratio.ToString($inv), ([math]::Round($r.minutes)).ToString($inv), $r.cost.ToString('0.00', $inv))
    }
    exit 0
}

$rows = @(Get-TaskUsage -Task $Task -ProjectPath $ProjectPath -Days $Days)
if ($null -eq $rows) {
    Write-Host "[warn] opencode CLI or session database is unavailable; token usage not collected" -ForegroundColor Yellow
    exit 0
}
if ($rows.Count -eq 0) {
    Write-Host "[warn] no sessions found for '$([System.IO.Path]::GetFileName($ProjectPath))'" -ForegroundColor Yellow
    if ($Task) {
        $empty = [pscustomobject]@{
            task = $Task; sessions = 0; input = 0; output = 0; reasoning = 0
            cache_read = 0; cost = 0.0; minutes = 0.0; ratio = 0
        }
        if ($Json) { $empty | ConvertTo-Json -Depth 4 }
        exit 0
    }
    exit 0
}

if ($Json) {
    if ($rows.Count -eq 1) { $rows[0] | ConvertTo-Json -Depth 4 }
    else { $rows | ConvertTo-Json -Depth 4 }
}

if ($Markdown -or $OutFile) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# Token usage")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("Project: ``$ProjectPath``")
    [void]$sb.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')")
    if ($Days -gt 0) { [void]$sb.AppendLine("Window: last $Days day(s)") }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Task | Sessions | Input | Output | Reasoning | Cache read | Cache/Input | Minutes | Cost |')
    [void]$sb.AppendLine('|---|---|---|---|---|---|---|---|---|')
    $inv = [System.Globalization.CultureInfo]::InvariantCulture
    foreach ($r in $rows) {
        [void]$sb.AppendLine(('| {0} | {1} | {2} | {3} | {4} | {5} | {6}x | {7} | ${8} |' -f `
                    $r.task, $r.sessions, $r.input, $r.output, $r.reasoning, $r.cache_read, `
                    $r.ratio.ToString($inv), ([math]::Round($r.minutes)).ToString($inv), $r.cost.ToString('0.00', $inv)))
    }
    $text = $sb.ToString()
    if ($OutFile) {
        $path = if ([System.IO.Path]::IsPathRooted($OutFile)) { $OutFile } else { Join-Path $Root $OutFile }
        Write-Utf8NoBom $path $text
        Write-Host "markdown: $path"
    }
    else {
        Write-Output $text
    }
}
elseif (-not $Json) {
    $inv = [System.Globalization.CultureInfo]::InvariantCulture
    foreach ($r in $rows) {
        Write-Host ("{0,-8} sessions={1,-3} in={2,-9} out={3,-8} reason={4,-8} cache_read={5,-10} ratio={6,5}x min={7,6} cost={8}" -f `
                $r.task, $r.sessions, $r.input, $r.output, $r.reasoning, $r.cache_read, `
                $r.ratio.ToString($inv), ([math]::Round($r.minutes)).ToString($inv), $r.cost.ToString('0.00', $inv))
    }
}
exit 0
