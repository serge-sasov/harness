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
    $stdout = @($output | Where-Object { $null -ne $_ -and $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { [string]$_ })
    $stderr = @($output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() })
    if ($code -ne 0 -and -not $AllowFail) {
        throw "git $($Arguments -join ' ') failed ($code): $((@($stderr) + @($stdout)) -join ' ')"
    }
    if ($code -eq 0 -and $stderr.Count -gt 0) {
        Write-Verbose ("git {0}: {1}" -f ($Arguments -join ' '), ($stderr -join ' '))
    }
    [pscustomobject]@{ ExitCode = $code; Output = $stdout; StdErr = $stderr }
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

function Get-SessionUsage {
    param(
        [string]$ProjectPath = (Get-Location).Path,
        [int]$Days = 0
    )
    $opencode = Get-Command opencode -ErrorAction SilentlyContinue
    if (-not $opencode) { return $null }
    $clauses = @()
    if ($ProjectPath) {
        $leaf = Split-Path -Leaf $ProjectPath
        if (-not $leaf) { $leaf = $ProjectPath }
        $safe = $leaf.Replace("'", "''")
        $clauses += "directory like '%$safe%'"
    }
    if ($Days -gt 0) {
        $clauses += "time_created >= (strftime('%s','now') - $($Days * 86400)) * 1000"
    }
    $where = if ($clauses.Count -gt 0) { 'where ' + ($clauses -join ' and ') } else { '' }
    $sql = "select id, coalesce(parent_id,'') p, title, tokens_input i, tokens_output o, tokens_reasoning rr, tokens_cache_read cr, cost, (time_updated-time_created)/60000 mins from session $where"
    $out = & $opencode.Source db $sql 2>&1
    if ($LASTEXITCODE -ne 0) { return $null }
    $lines = @($out | ForEach-Object { [string]$_ })
    if ($lines.Count -lt 2) { return @() }
    $rows = @()
    foreach ($line in $lines[1..($lines.Count - 1)]) {
        if (-not $line.Trim()) { continue }
        $c = $line -split "`t"
        if ($c.Count -lt 9) { continue }
        $rows += [pscustomobject]@{
            id         = $c[0]
            parent     = $c[1]
            title      = $c[2]
            input      = [int64]$c[3]
            output     = [int64]$c[4]
            reasoning  = [int64]$c[5]
            cache_read = [int64]$c[6]
            cost       = [double]$c[7]
            minutes    = [double]$c[8]
        }
    }
    $rows
}

function Get-ChunkUsage {
    param(
        [string]$Task = '',
        [string]$ProjectPath = (Get-Location).Path,
        [string]$SessionRoot = '',
        [int]$Days = 0
    )
    $sessions = @(Get-SessionUsage -ProjectPath $ProjectPath -Days $Days)
    if ($null -eq $sessions) { return $null }
    if ($sessions.Count -eq 0) { return @() }
    $byId = @{}
    foreach ($row in $sessions) { $byId[$row.id] = $row }
    $inSession = $null
    if ($SessionRoot) {
        $inSession = @{}
        foreach ($row in $sessions) {
            $cursor = $row
            $guard = 0
            while ($cursor -and $guard -lt 64) {
                if ($cursor.id -eq $SessionRoot) { $inSession[$row.id] = $true; break }
                $next = $cursor.parent
                if (-not $next -or -not $byId.ContainsKey($next)) { break }
                $cursor = $byId[$next]
                $guard++
            }
        }
        if ($inSession.Count -eq 0) { return @() }
    }
    $resolved = @{}
    foreach ($row in $sessions) {
        $taskId = '~'
        $chunkId = '~'
        $cursor = $row
        $guard = 0
        while ($cursor -and $guard -lt 64) {
            $m = [regex]::Match([string]$cursor.title, 'T-(\d{3,})(?:\.([A-Za-z0-9][A-Za-z0-9._-]*))?')
            if ($m.Success) {
                $taskId = 'T-' + $m.Groups[1].Value
                if ($m.Groups[2].Success) { $chunkId = $m.Groups[2].Value }
                break
            }
            $next = $cursor.parent
            if (-not $next -or -not $byId.ContainsKey($next)) { break }
            $cursor = $byId[$next]
            $guard++
        }
        $resolved[$row.id] = "$taskId|$chunkId"
    }
    $groups = @{}
    foreach ($row in $sessions) {
        if ($inSession -and -not $inSession.ContainsKey($row.id)) { continue }
        $key = $resolved[$row.id]
        if (-not $groups.ContainsKey($key)) {
            $parts = $key -split '\|', 2
            $groups[$key] = [pscustomobject]@{
                task = $parts[0]; chunk = $parts[1]; sessions = 0
                input = [int64]0; output = [int64]0; reasoning = [int64]0
                cache_read = [int64]0; cost = [double]0; minutes = [double]0
            }
        }
        $g = $groups[$key]
        $g.sessions += 1
        $g.input += $row.input
        $g.output += $row.output
        $g.reasoning += $row.reasoning
        $g.cache_read += $row.cache_read
        $g.cost += $row.cost
        $g.minutes += $row.minutes
    }
    $result = @($groups.Values | Sort-Object task, chunk)
    if ($Task -and -not $SessionRoot) { $result = @($result | Where-Object { $_.task -eq $Task }) }
    foreach ($g in $result) {
        $ratio = 0
        if ($g.input -gt 0) { $ratio = [math]::Round([double]$g.cache_read / [double]$g.input, 1) }
        $g | Add-Member -NotePropertyName ratio -NotePropertyValue $ratio -Force
    }
    $result
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

$script:HarnessSupportDir = Split-Path -Parent $PSScriptRoot

function Get-JsonPropertyValue {
    param($Object, [string]$Name)
    if ($null -eq $Object -or -not $Name) { return $null }
    if ($Object -is [hashtable]) {
        if ($Object.ContainsKey($Name)) { return $Object[$Name] }
        return $null
    }
    $prop = $Object.PSObject.Properties[$Name]
    if ($prop) { return $prop.Value }
    $null
}

function Get-SupportDir {
    param([string]$Root = '')
    if (-not $Root) { $Root = Get-HarnessRoot }
    $candidates = @()
    if ($script:HarnessSupportDir) { $candidates += $script:HarnessSupportDir }
    $candidates += @((Join-Path $Root 'harness'), (Join-Path $Root 'harness-sdd'))
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath (Join-Path $candidate 'process.md'))) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    $script:HarnessSupportDir
}

function Get-RiskPolicy {
    param([string]$Root = '')
    $support = Get-SupportDir -Root $Root
    if (-not $support) { throw "harness support directory not found" }
    $path = Join-Path $support 'checks\risk-policy.json'
    $result = [ordered]@{
        Path           = $path
        Exists         = $false
        Mode           = 'legacy'
        Engine         = ''
        DefaultTier    = 'medium'
        UnknownTier    = 'high'
        ReviewMode     = 'auto'
        MaxBatchStages = 4
        Data           = $null
    }
    if (-not (Test-Path -LiteralPath $path)) {
        return [pscustomobject]$result
    }
    try {
        $data = Read-Utf8 $path | ConvertFrom-Json
    }
    catch {
        throw "cannot parse risk policy '$path': $_"
    }
    $mode = [string](Get-JsonPropertyValue $data 'mode')
    if (-not $mode) { $mode = 'legacy' }
    $mode = $mode.ToLowerInvariant()
    if ($mode -notin @('legacy', 'risk')) {
        throw "risk policy '$path' has invalid mode '$mode' (expected legacy or risk)"
    }
    $result.Exists = $true
    $result.Mode = $mode
    $result.Engine = [string](Get-JsonPropertyValue $data 'engine')
    $defaultTier = [string](Get-JsonPropertyValue $data 'default_tier')
    if ($defaultTier) { $result.DefaultTier = $defaultTier }
    $unknownTier = [string](Get-JsonPropertyValue $data 'unknown_tier')
    if ($unknownTier) { $result.UnknownTier = $unknownTier }
    $reviewMode = [string](Get-JsonPropertyValue $data 'review_mode')
    if ($reviewMode) { $result.ReviewMode = $reviewMode }
    $maxBatch = Get-JsonPropertyValue $data 'max_batch_stages'
    if ($null -ne $maxBatch) { $result.MaxBatchStages = [int]$maxBatch }
    $result.Data = $data
    [pscustomobject]$result
}

function Get-ReviewGroups {
    param([string]$Root = '')
    $support = Get-SupportDir -Root $Root
    if (-not $support) { throw "harness support directory not found" }
    $path = Join-Path $support 'checks\review-groups.json'
    $result = [ordered]@{ Path = $path; Exists = $false; Data = $null }
    if (-not (Test-Path -LiteralPath $path)) { return [pscustomobject]$result }
    try {
        $data = Read-Utf8 $path | ConvertFrom-Json
    }
    catch {
        throw "cannot parse review groups '$path': $_"
    }
    $result.Exists = $true
    $result.Data = $data
    [pscustomobject]$result
}

function Get-ReviewGroupForStage {
    param($Config, [string]$Workflow, [string]$Stage)
    if (-not $Config -or -not $Workflow -or -not $Stage) { return $null }
    $data = Get-JsonPropertyValue $Config 'Data'
    if (-not $data) { $data = $Config }
    $workflowGroups = Get-JsonPropertyValue $data $Workflow
    foreach ($group in @($workflowGroups)) {
        if (@((Get-JsonPropertyValue $group 'stages')) -contains $Stage) { return $group }
    }
    $null
}

function Get-ReviewGroupById {
    param($Config, [string]$Id)
    if (-not $Config -or -not $Id) { return $null }
    $data = Get-JsonPropertyValue $Config 'Data'
    if (-not $data) { $data = $Config }
    foreach ($workflow in @('feature', 'bugfix', 'sdd')) {
        foreach ($group in @((Get-JsonPropertyValue $data $workflow))) {
            if ((Get-JsonPropertyValue $group 'id') -eq $Id) { return $group }
        }
    }
    $null
}

function Get-RiskRank {
    param([string]$Tier)
    switch (([string]$Tier).ToLowerInvariant()) {
        'low' { 0 }
        'medium' { 1 }
        'high' { 2 }
        'critical' { 3 }
        default { 3 }
    }
}

function Get-HighestRiskTier {
    param([string[]]$Tiers = @())
    $best = 'low'
    $bestRank = -1
    foreach ($tier in $Tiers) {
        if (-not $tier) { continue }
        $rank = Get-RiskRank $tier
        if ($rank -gt $bestRank) {
            $bestRank = $rank
            $best = $tier.ToLowerInvariant()
        }
    }
    $best
}

function Get-RiskFlagsForFiles {
    param([string[]]$Files = @(), [object[]]$FlagDefs = @())
    $hits = New-Object System.Collections.Generic.List[object]
    foreach ($def in @($FlagDefs)) {
        if (-not $def) { continue }
        $matched = @()
        $patterns = @((Get-JsonPropertyValue $def 'patterns'))
        foreach ($file in @($Files)) {
            if (-not $file) { continue }
            if (Test-GlobAny -Path $file -Patterns $patterns) { $matched += $file }
        }
        if ($matched.Count -gt 0) {
            $hits.Add([pscustomobject]@{
                    id    = [string](Get-JsonPropertyValue $def 'id')
                    tier  = [string](Get-JsonPropertyValue $def 'tier')
                    files = @($matched | Sort-Object -Unique)
                })
        }
    }
    $hits.ToArray()
}

function Get-ChangedFiles {
    param([string]$Root, [string]$BaseCommit = '')
    $set = New-Object 'System.Collections.Generic.HashSet[string]'
    function Add-GitLines {
        param($Lines)
        foreach ($line in @($Lines)) {
            if ($null -eq $line) { continue }
            $rel = ([string]$line).Trim().Replace('\', '/')
            if ($rel.StartsWith('./')) { $rel = $rel.Substring(2) }
            if ($rel) { [void]$set.Add($rel) }
        }
    }
    if ($BaseCommit -and $BaseCommit -ne '-') {
        $r = Invoke-Git -Root $Root -Arguments @('diff', '--name-only', "$BaseCommit..HEAD") -AllowFail
        if ($r.ExitCode -eq 0) { Add-GitLines $r.Output }
    }
    foreach ($gitArgs in @(
            @('diff', '--name-only'),
            @('diff', '--cached', '--name-only'),
            @('ls-files', '--others', '--exclude-standard')
        )) {
        $r = Invoke-Git -Root $Root -Arguments $gitArgs -AllowFail
        if ($r.ExitCode -eq 0) { Add-GitLines $r.Output }
    }
    @($set | Sort-Object)
}

function Get-CardStageFinalCheckpoint {
    param([string]$Path, [string]$Stage)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $null }
    $rows = @(Get-CardCheckpointRows -Path $Path | Where-Object {
            [string](Get-JsonPropertyValue $_ 'stage') -eq $Stage
        })
    if ($rows.Count -eq 0) { return $null }
    [string](Get-JsonPropertyValue $rows[$rows.Count - 1] 'id')
}

function Get-RiskAssessment {
    param(
        [string]$Root = (Get-Location).Path,
        [string]$Task = '',
        [string]$Workflow = 'feature',
        [string]$Stage = '',
        [string]$Checkpoint = '',
        [hashtable]$Card = @{},
        [string]$CardPath = '',
        [object]$Policy = $null,
        [object]$ReviewGroups = $null,
        [string[]]$ChangedFiles = @(),
        [string[]]$Artifacts = @(),
        [string]$BaseCommit = ''
    )
    if (-not $Policy) { $Policy = Get-RiskPolicy -Root $Root }
    if (-not $ReviewGroups) { $ReviewGroups = Get-ReviewGroups -Root $Root }
    $mode = [string]$Policy.Mode
    if (-not $mode) { $mode = 'legacy' }
    $tier = [string]$Policy.DefaultTier
    if (-not $tier) { $tier = 'medium' }
    $reasons = New-Object System.Collections.Generic.List[string]

    $stageTiers = Get-JsonPropertyValue $Policy.Data 'stage_tiers'
    $stageTier = [string](Get-JsonPropertyValue $stageTiers $Stage)
    if ($stageTier) {
        $tier = $stageTier
        $reasons.Add("stage $Stage tier $stageTier")
    }
    else {
        $tier = [string]$Policy.UnknownTier
        if (-not $tier) { $tier = 'high' }
        $reasons.Add("unknown stage $Stage tier $tier")
    }

    $allFiles = @(@($ChangedFiles) + @($Artifacts) | Where-Object { $_ } | Sort-Object -Unique)
    $flags = @()
    if ($allFiles.Count -gt 0) {
        $flags = @(Get-RiskFlagsForFiles -Files $allFiles -FlagDefs @((Get-JsonPropertyValue $Policy.Data 'flags')))
        foreach ($flag in $flags) {
            $tier = Get-HighestRiskTier @($tier, [string]$flag.tier)
            $reasons.Add("flag $($flag.id) tier $($flag.tier)")
        }
    }

    if ($Card -and $Card -is [hashtable]) {
        $override = ''
        foreach ($key in @('risk_tier', 'risk')) {
            if ($Card.ContainsKey($key)) {
                $value = ([string]$Card[$key]).Trim().ToLowerInvariant()
                if ($value -and $value -notin @('-', 'auto', 'default')) { $override = $value; break }
            }
        }
        if ($override) {
            $tier = Get-HighestRiskTier @($tier, $override)
            $reasons.Add("card risk override $override")
        }
    }

    $reviewMode = 'auto'
    if ($Policy.ReviewMode) { $reviewMode = [string]$Policy.ReviewMode }
    if ($Card -and $Card -is [hashtable] -and $Card.ContainsKey('review_mode')) {
        $value = ([string]$Card['review_mode']).Trim().ToLowerInvariant()
        if ($value -in @('auto', 'human')) { $reviewMode = $value }
    }

    $group = Get-ReviewGroupForStage -Config $ReviewGroups -Workflow $Workflow -Stage $Stage
    $groupId = ''
    $gate = ''
    $isBatchGate = $false
    if ($group) {
        $groupId = [string](Get-JsonPropertyValue $group 'id')
        $gateStage = [string](Get-JsonPropertyValue $group 'gate_stage')
        $gateCheckpoint = [string](Get-JsonPropertyValue $group 'gate_checkpoint')
        if ($gateStage -and $gateCheckpoint) { $gate = "$gateStage $gateCheckpoint" }
        if ($gateStage -eq $Stage -and $gateCheckpoint -eq $Checkpoint) { $isBatchGate = $true }
    }

    $closureStages = @((Get-JsonPropertyValue $Policy.Data 'closure_stages'))
    $uxGates = @((Get-JsonPropertyValue $Policy.Data 'ux_gates'))
    $isClosure = ($closureStages -contains $Stage)
    $isUxGate = ($uxGates -contains ('{0}:{1}' -f $Stage, $Checkpoint))

    $stageFinal = $null
    if ($CardPath) { $stageFinal = Get-CardStageFinalCheckpoint -Path $CardPath -Stage $Stage }
    if (-not $stageFinal -and $Card -and $Card -is [hashtable] -and $Card.ContainsKey('final_checkpoint')) {
        $stageFinal = ([string]$Card['final_checkpoint']).Trim()
        if ($stageFinal -eq '-') { $stageFinal = $null }
    }
    if (-not $stageFinal -and $Checkpoint -eq 'CP-F') { $stageFinal = 'CP-F' }
    $isStageFinal = ($stageFinal -and $Checkpoint -eq $stageFinal)

    [pscustomobject]@{
        Mode                 = $mode
        Task                 = $Task
        Workflow             = $Workflow
        Stage                = $Stage
        Checkpoint           = $Checkpoint
        RiskTier             = $tier.ToLowerInvariant()
        StageTier            = $stageTier
        Reasons              = @($reasons)
        Flags                = @($flags)
        Files                = @($allFiles)
        ReviewMode           = $reviewMode
        ReviewGroup          = $group
        ReviewGroupId        = $groupId
        Gate                 = $gate
        IsBatchGate          = $isBatchGate
        IsClosure            = $isClosure
        IsUxGate             = $isUxGate
        StageFinalCheckpoint = $stageFinal
        IsStageFinal         = $isStageFinal
    }
}

function Get-ApprovalDecision {
    param(
        [ValidateSet('legacy', 'risk')][string]$PolicyMode = 'legacy',
        [bool]$IsFinal = $false,
        [bool]$IsUxGate = $false,
        [bool]$LegacyUxGate = $false,
        [bool]$IsClosure = $false,
        [bool]$IsBatchGate = $false,
        [bool]$IsStageFinal = $false,
        [string]$RiskTier = 'medium',
        [string]$ReviewMode = 'auto',
        [bool]$Hold = $false,
        [int]$Fail = 0,
        [int]$Manual = 0,
        [int]$Unchecked = 0,
        [switch]$AutoApprove,
        [string]$ReviewGroup = '',
        [string]$Gate = ''
    )
    $result = [ordered]@{
        Approved      = $false
        Reviewer      = 'user'
        Decision      = '-'
        Reason        = ''
        HumanRequired = $true
        RiskTier      = $RiskTier
        PolicyMode    = $PolicyMode
        ReviewGroup   = $ReviewGroup
        Gate          = $Gate
    }
    $machineOk = ($Fail -eq 0 -and $Unchecked -eq 0)
    $autoOk = ($machineOk -and $Manual -eq 0)

    if ($PolicyMode -eq 'legacy') {
        if ($IsFinal) {
            if ($AutoApprove -and $autoOk) {
                $result.Approved = $true
                $result.Reviewer = 'auto (explicit -AutoApprove)'
                $result.Decision = 'approved'
                $result.HumanRequired = $false
                $result.Reason = 'legacy CP-F explicitly auto-approved with clean checks'
            }
            else {
                $result.Reason = 'legacy CP-F requires the user unless -AutoApprove is explicit and checks are clean'
            }
        }
        elseif ($LegacyUxGate) {
            $result.Reason = 'legacy UX prototype CP-2 requires the user'
        }
        elseif (-not $Hold -and $autoOk) {
            $result.Approved = $true
            $result.Reviewer = 'auto (legacy P2)'
            $result.Decision = 'approved'
            $result.HumanRequired = $false
            $result.Reason = 'legacy P2 auto-approved a clean non-gate checkpoint'
        }
        else {
            if ($Hold) { $result.Reason = 'hold: true requires the user' }
            elseif (-not $machineOk) { $result.Reason = 'failed or unchecked checks require the user' }
            else { $result.Reason = 'manual review requires the user' }
        }
        return [pscustomobject]$result
    }

    $tierRank = Get-RiskRank $RiskTier
    $reviewMode = ([string]$ReviewMode).ToLowerInvariant()
    if (-not $machineOk) {
        $result.Reason = 'failed or unchecked checks require the user'
    }
    elseif ($Manual -gt 0) {
        $result.Reason = 'manual review items require the user'
    }
    elseif ($Hold) {
        $result.Reason = 'hold: true requires the user'
    }
    elseif ($reviewMode -eq 'human') {
        $result.Reason = 'review_mode human requires the user'
    }
    elseif ($IsClosure) {
        $result.Reason = 'closure checkpoint requires the user'
    }
    elseif ($IsUxGate) {
        $result.Reason = 'UX gate requires the user'
    }
    elseif ($IsBatchGate) {
        $result.Reason = "batch gate $Gate requires the user"
    }
    elseif ($tierRank -ge 3) {
        $result.Reason = 'critical risk requires the user at every checkpoint'
    }
    elseif ($tierRank -ge 2) {
        if ($ReviewGroup -and -not $IsBatchGate) {
            $result.Approved = $true
            $result.Reviewer = 'auto (risk)'
            $result.Decision = 'approved'
            $result.HumanRequired = $false
            $result.Reason = 'high-risk stage inside a batch; covered by the group gate'
        }
        elseif (-not $ReviewGroup -and -not $IsStageFinal) {
            $result.Approved = $true
            $result.Reviewer = 'auto (risk)'
            $result.Decision = 'approved'
            $result.HumanRequired = $false
            $result.Reason = 'high-risk stage intermediate checkpoint'
        }
        else {
            $result.Reason = 'high risk at stage final or checkpoint gate requires the user'
        }
    }
    else {
        $result.Approved = $true
        $result.Reviewer = 'auto (risk)'
        $result.Decision = 'approved'
        $result.HumanRequired = $false
        $result.Reason = 'low/medium non-gate checkpoint auto-approved'
    }
    [pscustomobject]$result
}

function Get-CheckpointFields {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return @{} }
    $fields = Get-CardFields -Path $Path
    $fields
}

function Get-OpenCheckpoints {
    param([string]$Root)
    $dir = Join-Path $Root 'docs\checkpoints'
    if (-not (Test-Path -LiteralPath $dir)) { return @() }
    $rows = New-Object System.Collections.Generic.List[object]
    $cardCache = @{}
    $policy = Get-RiskPolicy -Root $Root
    $reviewGroups = Get-ReviewGroups -Root $Root
    foreach ($file in @(Get-ChildItem -LiteralPath $dir -Filter 'T-*-CP-*.md' -File -ErrorAction SilentlyContinue)) {
        $fields = Get-CheckpointFields -Path $file.FullName
        if ([string](Get-JsonPropertyValue $fields 'status') -ne 'awaiting_review') { continue }
        $task = [string](Get-JsonPropertyValue $fields 'task')
        $checkpoint = [string](Get-JsonPropertyValue $fields 'checkpoint')
        $workflow = [string](Get-JsonPropertyValue $fields 'workflow')
        $stage = [string](Get-JsonPropertyValue $fields 'stage')
        $riskTier = [string](Get-JsonPropertyValue $fields 'risk_tier')
        $policyMode = [string](Get-JsonPropertyValue $fields 'policy_mode')
        $reviewGroup = [string](Get-JsonPropertyValue $fields 'review_group')
        $gate = [string](Get-JsonPropertyValue $fields 'gate')
        $card = $null
        if ($task -and -not $cardCache.ContainsKey($task)) {
            $cardPath = Get-CardFile -Root $Root -Task $task
            $cardCache[$task] = if ($cardPath) { Get-CardFields -Path $cardPath } else { $null }
        }
        if ($task -and $cardCache.ContainsKey($task)) { $card = $cardCache[$task] }
        if (-not $workflow -and $card) { $workflow = [string](Get-JsonPropertyValue $card 'workflow') }
        if (-not $stage -and $card) { $stage = [string](Get-JsonPropertyValue $card 'stage') }
        if (-not $riskTier -or -not $reviewGroup -or -not $policyMode) {
            try {
                $risk = Get-RiskAssessment -Root $Root -Task $task -Workflow $workflow -Stage $stage `
                    -Checkpoint $checkpoint -Card $card -Policy $policy -ReviewGroups $reviewGroups
                if (-not $riskTier) { $riskTier = $risk.RiskTier }
                if (-not $policyMode) { $policyMode = $risk.Mode }
                if (-not $reviewGroup) { $reviewGroup = $risk.ReviewGroupId }
                if (-not $gate) { $gate = $risk.Gate }
            }
            catch { }
        }
        $requested = [string](Get-JsonPropertyValue $fields 'requested_at')
        $waitHours = $null
        if ($requested -and $requested -ne '-') {
            try {
                $dt = [datetime]::Parse($requested, [System.Globalization.CultureInfo]::InvariantCulture)
                $waitHours = [math]::Round(((Get-Date) - $dt).TotalHours, 1)
            }
            catch { }
        }
        $checksPath = $file.FullName -replace '\.md$', '.checks.json'
        $pass = 0; $fail = 0; $manual = 0; $unchecked = 0
        if (Test-Path -LiteralPath $checksPath) {
            try {
                $checks = Read-Utf8 $checksPath | ConvertFrom-Json
                $pass = [int]$checks.summary.pass
                $fail = [int]$checks.summary.fail
                $manual = [int]$checks.summary.manual
                $unchecked = [int]$checks.summary.unchecked
            }
            catch { }
        }
        $rows.Add([pscustomobject]@{
                Task         = $task
                Checkpoint   = $checkpoint
                Workflow     = $workflow
                Stage        = $stage
                Status       = [string](Get-JsonPropertyValue $fields 'status')
                RiskTier     = $riskTier
                PolicyMode   = $policyMode
                ReviewGroup  = $reviewGroup
                Gate         = $gate
                Reviewer     = [string](Get-JsonPropertyValue $fields 'reviewer')
                Decision     = [string](Get-JsonPropertyValue $fields 'decision')
                RequestedAt  = $requested
                WaitHours    = $waitHours
                Pass         = $pass
                Fail         = $fail
                Manual       = $manual
                Unchecked    = $unchecked
                Path         = $file.FullName
                ChecksFile   = $checksPath
            })
    }
    @($rows | Sort-Object RequestedAt, Task, Checkpoint)
}

function Get-CardEntries {
    param([string]$Root)
    $dir = Join-Path $Root 'docs\tasks'
    if (-not (Test-Path -LiteralPath $dir)) { return @() }
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($file in @(Get-ChildItem -LiteralPath $dir -Filter 'T-*.md' -File -ErrorAction SilentlyContinue)) {
        $fields = Get-CardFields -Path $file.FullName
        $fields['path'] = $file.FullName
        $rows.Add([pscustomobject]$fields)
    }
    @($rows | Sort-Object id)
}

function Set-CheckpointField {
    param([string]$Path, [string]$Name, [string]$Value)
    Set-CardField -Path $Path -Name $Name -Value $Value
}

function Add-MarkdownSectionItem {
    param([string]$Path, [string]$Heading, [string]$Item)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $content = Read-Utf8 $Path
    $pattern = "(?ms)^##\s+" + [regex]::Escape($Heading) + "\s*\r?\n(.*?)(?=^##\s+|\z)"
    $match = [regex]::Match($content, $pattern)
    if (-not $match.Success) {
        $content = $content.TrimEnd([char[]]"`r`n") + "`r`n`r`n## $Heading`r`n`r`n$Item`r`n"
    }
    else {
        $body = $match.Groups[1].Value
        $body = [regex]::Replace($body, '(?m)^-\s*\(user fills[^\r\n]*\)\s*\r?\n?', '')
        $body = $body.TrimEnd([char[]]"`r`n")
        if ($body) { $body += "`r`n" }
        $body += $Item + "`r`n"
        $replacement = "## $Heading`r`n`r`n" + $body + "`r`n"
        $content = $content.Substring(0, $match.Index) + $replacement + $content.Substring($match.Index + $match.Length)
    }
    Write-Utf8NoBom $Path $content
}
