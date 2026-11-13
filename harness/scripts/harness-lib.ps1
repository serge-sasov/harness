#requires -Version 5.1
# Shared helpers for harness scripts. Dot-source this file:
#   . (Join-Path $PSScriptRoot "harness-lib.ps1")

try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

function Read-Utf8 {
    param([Parameter(Mandatory = $true)][string]$Path)
    [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text
    )
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($false)))
}

function Get-HarnessRoot {
    param([string]$Start = (Get-Location).Path)
    $p = (Resolve-Path -LiteralPath $Start).Path
    while ($p) {
        if (Test-Path -LiteralPath (Join-Path $p "harness\process.md")) { return $p }
        if (Test-Path -LiteralPath (Join-Path $p ".git")) { return $p }
        $parent = Split-Path -Parent $p
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $p) { break }
        $p = $parent
    }
    (Resolve-Path -LiteralPath $Start).Path
}

function ConvertTo-ForwardSlash {
    param([string]$Path)
    $Path.Replace('\', '/')
}

function Get-AllFiles {
    param([Parameter(Mandatory = $true)][string]$Root)
    $rootFull = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\')
    $rootLen = $rootFull.Length + 1
    $exclude = '\\(\.git|node_modules|bin|obj|__pycache__|\.harness-backup[^\\]*)(\\|$)'
    Get-ChildItem -LiteralPath $rootFull -Recurse -File -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            $rel = $_.FullName.Substring($rootLen).Replace('\', '/')
            if ($rel -notmatch $exclude) { $rel }
        }
}

function ConvertTo-GlobRegex {
    param([Parameter(Mandatory = $true)][string]$Glob)
    $g = ConvertTo-ForwardSlash $Glob
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('^')
    for ($i = 0; $i -lt $g.Length; $i++) {
        $ch = $g[$i]
        if ($ch -eq '*') {
            if ($i + 1 -lt $g.Length -and $g[$i + 1] -eq '*') {
                [void]$sb.Append('.*')
                $i++
            }
            else {
                [void]$sb.Append('[^/]*')
            }
        }
        elseif ($ch -eq '?') {
            [void]$sb.Append('[^/]')
        }
        else {
            [void]$sb.Append([regex]::Escape([string]$ch))
        }
    }
    [void]$sb.Append('$')
    $sb.ToString()
}

function Expand-Glob {
    param(
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string[]]$AllFiles
    )
    $rx = ConvertTo-GlobRegex $Pattern
    @($AllFiles | Where-Object { $_ -match $rx } | Sort-Object -Unique)
}

function Expand-Artifacts {
    param(
        [string[]]$Items = @(),
        [string[]]$AllFiles = @(),
        [string]$Root = (Get-Location).Path
    )
    $result = New-Object System.Collections.Generic.List[string]
    $unresolved = New-Object System.Collections.Generic.List[string]
    foreach ($raw in $Items) {
        foreach ($piece in ([string]$raw -replace '`', '').Split(',')) {
            $item = $piece.Trim()
            if (-not $item -or $item -eq '-') { continue }
            if ($item -match '\.\.') {
                $parts = $item -split '\.\.', 2
                $leftM = [regex]::Match($parts[0], '^(?<dir>.*/)?(?<pre>[^/]*?)(?<num>\d+)(?<ext>\.[A-Za-z0-9]+)$')
                $rightM = [regex]::Match($parts[1], '^(?<pre>[^/]*?)(?<num>\d+)(?<ext>\.[A-Za-z0-9]+)$')
                if ($leftM.Success -and $rightM.Success) {
                    $dirV = $leftM.Groups['dir'].Value
                    $preV = $rightM.Groups['pre'].Value
                    if (-not $preV) { $preV = $leftM.Groups['pre'].Value }
                    $extV = $rightM.Groups['ext'].Value
                    $n1 = [int]$leftM.Groups['num'].Value
                    $n2 = [int]$rightM.Groups['num'].Value
                    $width = $leftM.Groups['num'].Value.Length
                    for ($n = $n1; $n -le $n2; $n++) {
                        $result.Add(('{0}{1}{2}{3}' -f $dirV, $preV, $n.ToString("D$width"), $extV))
                    }
                    continue
                }
            }
            if ($item -match '[*?\[]') {
                $found = Expand-Glob -Pattern $item -AllFiles $AllFiles
                if ($found.Count -eq 0) { $unresolved.Add($item) }
                else { foreach ($f in $found) { $result.Add($f) } }
            }
            elseif (Test-Path -LiteralPath (Join-Path $Root $item)) {
                $result.Add((ConvertTo-ForwardSlash $item))
            }
            else {
                $unresolved.Add($item)
            }
        }
    }
    [pscustomobject]@{
        Files      = @($result | Sort-Object -Unique)
        Unresolved = @($unresolved | Sort-Object -Unique)
    }
}

function Test-GlobAny {
    param([string]$Path, [string[]]$Patterns = @())
    $p = ConvertTo-ForwardSlash $Path
    foreach ($pattern in $Patterns) {
        if (-not $pattern) { continue }
        if ($p -match (ConvertTo-GlobRegex $pattern)) { return $true }
    }
    $false
}

function Get-CardFile {
    param([string]$Root, [string]$Task)
    $dir = Join-Path $Root "docs\tasks"
    if (-not (Test-Path -LiteralPath $dir)) { return $null }
    $item = Get-ChildItem -LiteralPath $dir -Filter "$Task-*.md" -File -ErrorAction SilentlyContinue |
        Sort-Object Name | Select-Object -First 1
    if (-not $item) {
        $item = Get-ChildItem -LiteralPath $dir -Filter "$Task*.md" -File -ErrorAction SilentlyContinue |
            Sort-Object Name | Select-Object -First 1
    }
    if ($item) { $item.FullName } else { $null }
}

function Get-CardFields {
    param([Parameter(Mandatory = $true)][string]$Path)
    $fields = @{}
    foreach ($line in ((Read-Utf8 $Path) -split "`r?`n")) {
        if ($line -match '^\|\s*([A-Za-z_]+)\s*\|\s*(.*?)\s*\|\s*$') {
            $key = $Matches[1].ToLowerInvariant()
            if ($key -eq 'field') { continue }
            if (-not $fields.ContainsKey($key)) { $fields[$key] = $Matches[2] }
        }
    }
    $fields
}

function Set-CardField {
    param([string]$Path, [string]$Name, [string]$Value)
    $text = Read-Utf8 $Path
    $pattern = "(?m)^(\|\s*" + [regex]::Escape($Name) + "\s*\|\s*).*?(\s*\|\s*)$"
    if (-not [regex]::IsMatch($text, $pattern)) { return $false }
    $text = [regex]::Replace($text, $pattern, {
            param($m)
            $m.Groups[1].Value + $Value + $m.Groups[2].Value
        }, 1)
    Write-Utf8NoBom $Path $text
    $true
}

function Get-BoardTable {
    param([Parameter(Mandatory = $true)][string]$Root)
    $path = Join-Path $Root "docs\plan.md"
    if (-not (Test-Path -LiteralPath $path)) { return [pscustomobject]@{ Path = $path; Columns = @(); Rows = @() } }
    $lines = (Read-Utf8 $path) -split "`r?`n"
    $inBoard = $false
    $columns = @()
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($line in $lines) {
        if ($line -match '^##\s+Board\s*$') { $inBoard = $true; continue }
        if ($inBoard -and $line -match '^##\s') { break }
        if (-not $inBoard) { continue }
        if ($line -match '^\|\s*ID\s*\|') {
            $columns = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim().ToLowerInvariant() })
            continue
        }
        if ($columns.Count -eq 0 -or $line -notmatch '^\|') { continue }
        if ($line -match '^\|\s*-') { continue }
        $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
        if ($cells.Count -eq 0 -or $cells[0] -notmatch '^T-\d{3,}$') { continue }
        $row = [ordered]@{}
        for ($i = 0; $i -lt $columns.Count -and $i -lt $cells.Count; $i++) {
            $row[$columns[$i]] = $cells[$i]
        }
        $rows.Add([pscustomobject]$row)
    }
    [pscustomobject]@{ Path = $path; Columns = $columns; Rows = $rows.ToArray() }
}

function Set-BoardRow {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Task,
        [Parameter(Mandatory = $true)][hashtable]$Values
    )
    $board = Get-BoardTable -Root $Root
    if ($board.Columns.Count -eq 0) { return 0 }
    $lines = (Read-Utf8 $board.Path) -split "`r?`n"
    $changed = 0
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        if ($line -match ('^\|\s*' + [regex]::Escape($Task) + '\s*\|')) {
            $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
            for ($i = 0; $i -lt $board.Columns.Count -and $i -lt $cells.Count; $i++) {
                $col = $board.Columns[$i]
                if ($Values.ContainsKey($col)) { $cells[$i] = [string]$Values[$col] }
            }
            $line = '| ' + ($cells -join ' | ') + ' |'
            $changed++
        }
        $out.Add($line)
    }
    if ($changed -gt 0) { Write-Utf8NoBom $board.Path ($out -join "`r`n") }
    $changed
}

function Get-CardCheckpointRows {
    param([string]$Path)
    $lines = (Read-Utf8 $Path) -split "`r?`n"
    $inTable = $false
    $columns = @()
    $rows = @()
    foreach ($line in $lines) {
        if ($line -match '^##\s+Checkpoints') { $inTable = $true; continue }
        if ($inTable -and $line -match '^##\s') { break }
        if (-not $inTable) { continue }
        if ($line -match '^\|\s*ID\s*\|') {
            $columns = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim().ToLowerInvariant() })
            continue
        }
        if ($columns.Count -eq 0 -or $line -notmatch '^\|') { continue }
        if ($line -match '^\|\s*-') { continue }
        $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
        if ($cells.Count -eq 0 -or $cells[0] -notmatch '^CP-') { continue }
        $row = [ordered]@{}
        for ($i = 0; $i -lt $columns.Count -and $i -lt $cells.Count; $i++) { $row[$columns[$i]] = $cells[$i] }
        $rows += [pscustomobject]$row
    }
    @($rows)
}

function Get-CardAcceptanceItems {
    param([string]$Path)
    $lines = (Read-Utf8 $Path) -split "`r?`n"
    $inSection = $false
    $items = @()
    foreach ($line in $lines) {
        if ($line -match '^##\s+Acceptance') { $inSection = $true; continue }
        if ($inSection -and $line -match '^##\s') { break }
        if ($inSection -and $line -match '^\s*[-*]\s+(?:\[[ xX]\]\s*)?(.+)$') {
            $items += $Matches[1].Trim()
        }
    }
    @($items)
}

function Get-CheckpointFile {
    param([string]$Root, [string]$Task, [string]$Checkpoint)
    $path = Join-Path $Root "docs\checkpoints\$Task-$Checkpoint.md"
    if (Test-Path -LiteralPath $path) { return $path }
    $null
}

function Get-CheckpointField {
    param([string]$Path, [string]$Name)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $null }
    $rx = '(?m)^\|\s*' + [regex]::Escape($Name) + '\s*\|\s*(.*?)\s*\|\s*$'
    $m = [regex]::Match((Read-Utf8 $Path), $rx)
    if ($m.Success) { $m.Groups[1].Value.Trim() } else { $null }
}

function Set-CardCheckpointRow {
    param([string]$Path, [string]$Checkpoint, [string]$Status, [string]$ReviewFile, [string]$Checks)
    $lines = (Read-Utf8 $Path) -split "`r?`n"
    $inTable = $false
    $columns = @()
    $changed = 0
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        if ($line -match '^##\s+Checkpoints\s*$') { $inTable = $true; $out.Add($line); continue }
        if ($inTable -and $line -match '^##\s') { $inTable = $false; $out.Add($line); continue }
        if ($inTable -and $line -match '^\|\s*ID\s*\|') {
            $columns = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim().ToLowerInvariant() })
            $out.Add($line)
            continue
        }
        if ($inTable -and $columns.Count -gt 0 -and $line -match ('^\|\s*' + [regex]::Escape($Checkpoint) + '\s*\|')) {
            $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
            for ($i = 0; $i -lt $columns.Count -and $i -lt $cells.Count; $i++) {
                if ($columns[$i] -eq 'status') { $cells[$i] = $Status }
                if ($columns[$i] -eq 'review file' -and $ReviewFile) { $cells[$i] = $ReviewFile }
                if ($columns[$i] -eq 'checks' -and $Checks) { $cells[$i] = $Checks }
            }
            $line = '| ' + ($cells -join ' | ') + ' |'
            $changed++
        }
        $out.Add($line)
    }
    if ($changed -gt 0) { Write-Utf8NoBom $Path ($out -join "`r`n") }
    $changed
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [string[]]$Arguments = @(),
        [switch]$AllowFail
    )
    $previousEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & git -C $Root @Arguments 2>&1
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousEap
    }
    if ($code -ne 0 -and -not $AllowFail) {
        throw "git $($Arguments -join ' ') failed ($code): $($output -join ' ')"
    }
    [pscustomobject]@{ ExitCode = $code; Output = @($output) }
}

function Get-BoardStatusColor {
    param([string]$Status)
    switch ($Status) {
        'done' { '#90EE90' }
        'in_progress' { '#FFE082' }
        'awaiting_review' { '#87CEFA' }
        'pending' { '#D3D3D3' }
        'failed' { '#FF9090' }
        'blocked' { '#FFB347' }
        default { '#D3D3D3' }
    }
}

function Resolve-PlantumlJar {
    if ($env:PLANTUML_JAR -and (Test-Path -LiteralPath $env:PLANTUML_JAR)) { return $env:PLANTUML_JAR }
    $global = Join-Path $env:USERPROFILE ".config\opencode\mcp\plantuml-render\plantuml.jar"
    if (Test-Path -LiteralPath $global) { return $global }
    $vendor = Join-Path (Get-HarnessRoot) "harness\vendor\plantuml.jar"
    if (Test-Path -LiteralPath $vendor) { return $vendor }
    $null
}

function Resolve-Java {
    if ($env:JAVA_HOME) {
        $candidate = Join-Path $env:JAVA_HOME "bin\java.exe"
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    $cmd = Get-Command java -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $jdk = Get-ChildItem -LiteralPath (Join-Path $env:USERPROFILE ".jdks") -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    if ($jdk) {
        $candidate = Join-Path $jdk.FullName "bin\java.exe"
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    $null
}

function Sync-Activity {
    param([Parameter(Mandatory = $true)][string]$Root)
    $board = Get-BoardTable -Root $Root
    if ($board.Rows.Count -eq 0) { return [pscustomobject]@{ Rendered = $false; Reason = 'empty board' } }
    $pumlPath = Join-Path $Root "docs\activity.puml"
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('@startuml')
    $lines.Add('skinparam defaultFontName Segoe UI')
    $lines.Add('skinparam ActivityBackgroundColor #FFFFFF')
    $lines.Add('skinparam ActivityBorderColor #555555')
    $lines.Add('skinparam ArrowColor #555555')
    $ids = @($board.Rows | ForEach-Object { $_.id })
    $lines.Add(('title Local harness - task plan {0}..{1}' -f $ids[0], $ids[-1]))
    $lines.Add('')
    $lines.Add('start')
    foreach ($row in $board.Rows) {
        $title = [string]$row.task
        $title = $title -replace ';', ',' -replace "`r", ' ' -replace "`n", ' '
        if ($title.Length -gt 70) { $title = $title.Substring(0, 67) + '...' }
        $color = Get-BoardStatusColor $row.status
        $lines.Add((':{0} {1}; <<{2}>>' -f $row.id, $title, $color))
    }
    $lines.Add('stop')
    $lines.Add('')
    $lines.Add('legend right')
    $lines.Add('|= Color |= Status |')
    $lines.Add('|<#90EE90>| done |')
    $lines.Add('|<#FFE082>| in_progress |')
    $lines.Add('|<#87CEFA>| awaiting_review |')
    $lines.Add('|<#D3D3D3>| pending |')
    $lines.Add('|<#FF9090>| failed |')
    $lines.Add('|<#FFB347>| blocked |')
    $lines.Add('| (derived) | Informational only; board/card is authoritative |')
    $lines.Add('endlegend')
    $lines.Add('@enduml')
    Write-Utf8NoBom $pumlPath ($lines -join "`r`n")

    $jar = Resolve-PlantumlJar
    $java = Resolve-Java
    if (-not $jar -or -not $java) {
        return [pscustomobject]@{ Rendered = $false; Reason = 'plantuml.jar or java not found'; Puml = $pumlPath }
    }
    & $java -jar $jar -tsvg $pumlPath 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        return [pscustomobject]@{ Rendered = $false; Reason = "plantuml exit $LASTEXITCODE"; Puml = $pumlPath }
    }
    [pscustomobject]@{ Rendered = $true; Puml = $pumlPath; Svg = (Join-Path $Root "docs\activity.svg") }
}

function Get-TaskUsage {
    param(
        [string]$Task,
        [string]$ProjectPath = (Get-Location).Path,
        [int]$Days = 0
    )
    $opencode = Get-Command opencode -ErrorAction SilentlyContinue
    if (-not $opencode) { return $null }
    $leaf = Split-Path -Leaf $ProjectPath
    if (-not $leaf) { $leaf = $ProjectPath }
    $safe = $leaf.Replace("'", "''")
    $where = "directory like '%$safe%'"
    if ($Days -gt 0) {
        $where += " and time_created >= (strftime('%s','now') - $($Days * 86400)) * 1000"
    }
    $sql = @"
with recursive s as (
  select id,parent_id,title,tokens_input i,tokens_output o,tokens_reasoning rr,tokens_cache_read cr,cost,(time_updated-time_created)/60000 mins
  from session where $where
), chain(id,parent_id,tid,i,o,rr,cr,cost,mins) as (
  select id,parent_id,
    case when title glob '*T-[0-9][0-9][0-9]*' then substr(title,instr(title,'T-'),5) else null end,
    i,o,rr,cr,cost,mins
  from s where parent_id is null
  union all
  select c.id,c.parent_id,
    coalesce(ch.tid, case when c.title glob '*T-[0-9][0-9][0-9]*' then substr(c.title,instr(c.title,'T-'),5) else null end),
    c.i,c.o,c.rr,c.cr,c.cost,c.mins
  from chain ch join s c on c.parent_id=ch.id
)
select coalesce(tid,'~') task,count(*) sessions,sum(i) inp,sum(o) outp,sum(rr) reasoning,sum(cr) cache_read,sum(cost) cost,sum(mins) mins
from chain group by 1 order by 1
"@
    $out = & $opencode.Source db $sql 2>&1
    if ($LASTEXITCODE -ne 0) { return $null }
    $lines = @($out | ForEach-Object { [string]$_ })
    if ($lines.Count -lt 2) { return @() }
    $rows = @()
    foreach ($line in $lines[1..($lines.Count - 1)]) {
        if (-not $line.Trim()) { continue }
        $c = $line -split "`t"
        if ($c.Count -lt 8) { continue }
        $rows += [pscustomobject]@{
            task       = $c[0]
            sessions   = [int]$c[1]
            input      = [int64]$c[2]
            output     = [int64]$c[3]
            reasoning  = [int64]$c[4]
            cache_read = [int64]$c[5]
            cost       = [double]$c[6]
            minutes    = [double]$c[7]
            ratio      = if ([int64]$c[2] -gt 0) { [math]::Round([double]$c[5] / [double]$c[2], 1) } else { 0 }
        }
    }
    if ($Task) {
        $rows | Where-Object { $_.task -eq $Task } | Select-Object -First 1
    }
    else {
        $rows
    }
}

function Get-TaskBaseCommit {
    param([string]$Root, [hashtable]$Card, [string]$Task)
    if ($Card -and $Card.ContainsKey('base_commit')) {
        $v = (($Card['base_commit']) -replace '`', '').Trim()
        if ($v -and $v -ne '-') { return $v }
    }
    $dir = Join-Path $Root "docs\checkpoints"
    if (Test-Path -LiteralPath $dir) {
        $files = Get-ChildItem -LiteralPath $dir -Filter "$Task-CP-*.md" -File -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending
        foreach ($file in $files) {
            $v = Get-CheckpointField -Path $file.FullName -Name 'snapshot_commit'
            if ($v) {
                $hash = [regex]::Match($v, '`?([0-9a-f]{7,40})`?').Groups[1].Value
                if ($hash) { return $hash }
            }
        }
    }
    $r = Invoke-Git -Root $Root -Arguments @('rev-parse', 'HEAD') -AllowFail
    if ($r.ExitCode -eq 0 -and $r.Output.Count -gt 0) { return ([string]$r.Output[0]).Trim() }
    $null
}
