#requires -Version 5.1
<#
.SYNOPSIS
Deterministic artifact verification for the local harness.

.DESCRIPTION
Runs universal and stage checks from harness/checks/*.json against the current
project. Results: PASS, FAIL, MANUAL, NOT_APPLICABLE. UNCHECKED is computed for
declared artifacts that no check covers.

.EXAMPLE
.\verify-artifacts.ps1 -Task T-005 -Stage U-02
.\verify-artifacts.ps1 -Task T-005 -Stage U-02 -Json docs/checkpoints/T-005-CP-F.checks.json
.\verify-artifacts.ps1 -SelfTest
#>
[CmdletBinding()]
param(
    [string]$Task,
    [string]$Stage,
    [ValidateSet('auto', 'feature', 'bugfix')][string]$Workflow = 'auto',
    [string]$Root = '',
    [string]$ChecksDir = '',
    [string]$Json,
    [string]$Check,
    [switch]$List,
    [switch]$WarnOnly,
    [switch]$SelfTest
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "harness-lib.ps1")

function New-Result {
    param([string]$Id, [string]$CheckType, [string]$Result, [string]$Detail)
    [pscustomobject]@{
        id     = $Id
        check  = $CheckType
        result = $Result
        detail = $Detail
    }
}

function Get-FilesForParams {
    param($P, $Ctx)
    if ($null -eq $P) { return @() }
    $files = @()
    if ($P.source -eq 'card.artifacts') {
        $files = @($Ctx.Artifacts)
    }
    elseif ($P.source -eq 'card.inputs') {
        $files = @($Ctx.Inputs | Where-Object { $_ })
    }
    elseif ($P.globs) {
        foreach ($g in @($P.globs)) {
            if ($g) { $files += Expand-Glob -Pattern ([string]$g) -AllFiles $Ctx.AllFiles }
        }
    }
    elseif ($P.glob) {
        $files = @(Expand-Glob -Pattern ([string]$P.glob) -AllFiles $Ctx.AllFiles)
    }
    $files = @($files | Sort-Object -Unique)
    if ($P.scope -eq 'card') {
        $files = @($files | Where-Object { $Ctx.Artifacts -contains $_ })
    }
    $files
}

function Get-FileTextSafe {
    param([string]$Root, [string]$RelPath)
    $full = Join-Path $Root $RelPath
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { return $null }
    Read-Utf8 $full
}

function Check-FileExists {
    param($P, $Ctx)
    $files = Get-FilesForParams $P $Ctx
    $minCount = 1
    if ($null -ne $P.minCount) { $minCount = [int]$P.minCount }
    $minBytes = 1
    if ($null -ne $P.minBytes) { $minBytes = [int]$P.minBytes }
    $bad = @()
    if ($P.source -eq 'card.artifacts' -and $Ctx.Unresolved) {
        foreach ($u in @($Ctx.Unresolved)) { $bad += "$u (unresolved from card)" }
    }
    foreach ($f in $files) {
        $full = Join-Path $Ctx.Root $f
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
            $bad += "$f (missing)"
        }
        elseif ((Get-Item -LiteralPath $full).Length -lt $minBytes) {
            $bad += "$f (< $minBytes B)"
        }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'file-exists' 'FAIL' (($bad | Select-Object -First 6) -join '; ') }
    if ($files.Count -lt $minCount) {
        return New-Result $P.id 'file-exists' 'FAIL' "found $($files.Count), required >= $minCount"
    }
    New-Result $P.id 'file-exists' 'PASS' "$($files.Count) file(s)"
}

function Check-Pattern {
    param($P, $Ctx, [switch]$Absent)
    $files = Get-FilesForParams $P $Ctx
    $patterns = @($P.patterns | Where-Object { $_ })
    $ignoreCase = [bool]$P.ignoreCase
    $hits = @()
    $foundPatterns = @{}
    $rxHits = 0
    foreach ($f in $files) {
        $text = Get-FileTextSafe -Root $Ctx.Root -RelPath $f
        if ($null -eq $text) { continue }
        $lines = $text -split "`r?`n"
        $rx = $null
        if ($P.regex) { $rx = [regex]::new([string]$P.regex, $(if ($ignoreCase) { 'IgnoreCase' } else { 'None' })) }
        for ($i = 0; $i -lt $lines.Count; $i++) {
            foreach ($pat in $patterns) {
                $patText = [string]$pat
                $isHit = if ($ignoreCase) {
                    $lines[$i].IndexOf($patText, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
                }
                else {
                    $lines[$i].IndexOf($patText, [System.StringComparison]::Ordinal) -ge 0
                }
                if ($isHit) {
                    $hits += "${f}:$($i + 1) '$patText'"
                    $foundPatterns[$patText] = $true
                }
            }
            if ($rx -and $rx.IsMatch($lines[$i])) {
                $hits += "${f}:$($i + 1) /$($P.regex)/"
                $rxHits++
            }
        }
    }
    if ($Absent) {
        if ($hits.Count -gt 0) {
            $shown = @($hits | Select-Object -First 5) -join '; '
            if ($hits.Count -gt 5) { $shown += " (+$($hits.Count - 5) more)" }
            return New-Result $P.id 'pattern-absent' 'FAIL' $shown
        }
        return New-Result $P.id 'pattern-absent' 'PASS' "$($patterns.Count) pattern(s) absent in $($files.Count) file(s)"
    }
    if ($patterns.Count -eq 0 -and $P.regex) {
        if ($rxHits -eq 0) { return New-Result $P.id 'pattern-present' 'FAIL' "regex /$($P.regex)/ not found" }
        return New-Result $P.id 'pattern-present' 'PASS' "regex matched $rxHits line(s)"
    }
    $missing = @($patterns | Where-Object { -not $foundPatterns.ContainsKey([string]$_) })
    if ($missing.Count -gt 0) {
        return New-Result $P.id 'pattern-present' 'FAIL' ("missing: " + ($missing -join ', '))
    }
    New-Result $P.id 'pattern-present' 'PASS' "$($patterns.Count) pattern(s) in $($files.Count) file(s)"
}

function Check-Headings {
    param($P, $Ctx)
    $files = Get-FilesForParams $P $Ctx
    $headings = @($P.headings | Where-Object { $_ })
    $allFiles = $true
    if ($null -ne $P.allFiles) { $allFiles = [bool]$P.allFiles }
    if ($files.Count -eq 0) { return New-Result $P.id 'headings-required' 'FAIL' 'no files matched' }
    $bad = @()
    $checked = 0
    foreach ($f in $files) {
        $text = Get-FileTextSafe -Root $Ctx.Root -RelPath $f
        if ($null -eq $text) { $bad += "$f (missing)"; continue }
        $missing = @()
        foreach ($h in $headings) {
            $rx = '(?m)^\s*' + [regex]::Escape([string]$h)
            if (-not [regex]::IsMatch($text, $rx)) { $missing += $h }
        }
        if ($missing.Count -gt 0 -and $allFiles) { $bad += "$f missing: $($missing -join ', ')" }
        $checked++
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'headings-required' 'FAIL' (($bad | Select-Object -First 5) -join '; ') }
    New-Result $P.id 'headings-required' 'PASS' "$checked file(s)"
}

function Check-PumlSyntax {
    param($P, $Ctx)
    $files = Get-FilesForParams $P $Ctx
    if ($files.Count -eq 0) { return New-Result $P.id 'puml-syntax' 'FAIL' 'no .puml files matched' }
    $bad = @()
    foreach ($f in $files) {
        $text = Get-FileTextSafe -Root $Ctx.Root -RelPath $f
        if ($null -eq $text) { $bad += "$f (missing)"; continue }
        $starts = ([regex]::Matches($text, '(?m)^\s*@start\w+')).Count
        $ends = ([regex]::Matches($text, '(?m)^\s*@end\w+')).Count
        if ($starts -eq 0 -or $ends -eq 0) { $bad += "$f (missing @start.../@end...)" }
        elseif ($starts -ne $ends) { $bad += "$f (@start=$starts, @end=$ends)" }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'puml-syntax' 'FAIL' ($bad -join '; ') }
    New-Result $P.id 'puml-syntax' 'PASS' "$($files.Count) diagram(s)"
}

function Check-SvgFresh {
    param($P, $Ctx)
    $pumls = Get-FilesForParams $P $Ctx
    if ($pumls.Count -eq 0) { return New-Result $P.id 'svg-fresh' 'FAIL' 'no .puml files matched' }
    $bad = @()
    $ok = 0
    $errorRx = [regex]::new('(syntax\s+error|deprecated\s+syntax|cannot\s+be\s+parsed)', 'IgnoreCase')
    foreach ($puml in $pumls) {
        $svg = [regex]::Replace($puml, '\.puml$', '.svg', 'IgnoreCase')
        $full = Join-Path $Ctx.Root $svg
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { $bad += "$svg (missing)"; continue }
        if ((Get-Item -LiteralPath $full).Length -lt 1000) { $bad += "$svg (< 1000 B)"; continue }
        $text = Read-Utf8 $full
        if ($errorRx.IsMatch($text)) { $bad += "$svg (render error text)"; continue }
        $ok++
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'svg-fresh' 'FAIL' ($bad -join '; ') }
    New-Result $P.id 'svg-fresh' 'PASS' "$ok SVG(s)"
}

function Check-HtmlStructure {
    param($P, $Ctx)
    $files = Get-FilesForParams $P $Ctx
    if ($files.Count -eq 0) { return New-Result $P.id 'html-structure' 'FAIL' 'no .html files matched' }
    $bad = @()
    foreach ($f in $files) {
        $text = Get-FileTextSafe -Root $Ctx.Root -RelPath $f
        if ($null -eq $text) { $bad += "$f (missing)"; continue }
        $missing = @()
        if ($text -notmatch '(?i)</html>') { $missing += '</html>' }
        if ($text -notmatch '(?i)<html\b') { $missing += '<html>' }
        if ($text -notmatch '(?i)<title>') { $missing += '<title>' }
        if ($P.lang) {
            if ($text -notmatch ('(?i)<html[^>]*\blang="' + [regex]::Escape([string]$P.lang) + '"')) { $missing += "lang=$($P.lang)" }
        }
        elseif ($text -notmatch '(?i)<html[^>]*\blang="[a-z]{2}') {
            $missing += 'lang'
        }
        if ($missing.Count -gt 0) { $bad += "$f missing: $($missing -join ', ')" }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'html-structure' 'FAIL' (($bad | Select-Object -First 5) -join '; ') }
    New-Result $P.id 'html-structure' 'PASS' "$($files.Count) page(s)"
}

function Check-HtmlLinks {
    param($P, $Ctx)
    $files = Get-FilesForParams $P $Ctx
    $bad = @()
    $checked = 0
    foreach ($f in $files) {
        $text = Get-FileTextSafe -Root $Ctx.Root -RelPath $f
        if ($null -eq $text) { $bad += "$f (missing)"; continue }
        $dir = Split-Path -Parent (Join-Path $Ctx.Root $f)
        foreach ($m in [regex]::Matches($text, '(?i)(?:href|src)="([^"]+)"')) {
            $link = $m.Groups[1].Value.Trim()
            if ($link -match '^(#|https?:|mailto:|data:|javascript:|//)') { continue }
            $link = ($link -split '[?#]')[0]
            if (-not $link) { continue }
            $target = Join-Path $dir $link
            if (-not (Test-Path -LiteralPath $target)) { $bad += "$f -> $link" }
            $checked++
        }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'html-links-exist' 'FAIL' (($bad | Select-Object -First 6) -join '; ') }
    New-Result $P.id 'html-links-exist' 'PASS' "$checked local link(s)"
}

function Check-IndexPages {
    param($P, $Ctx)
    $indexes = @($P.indexGlobs | Where-Object { $_ } | ForEach-Object { Expand-Glob -Pattern ([string]$_) -AllFiles $Ctx.AllFiles } | Sort-Object -Unique)
    $pages = @($P.pagesGlobs | Where-Object { $_ } | ForEach-Object { Expand-Glob -Pattern ([string]$_) -AllFiles $Ctx.AllFiles } | Sort-Object -Unique)
    if ($P.scope -eq 'card') {
        $indexes = @($indexes | Where-Object { $Ctx.Artifacts -contains $_ })
        $pages = @($pages | Where-Object { $Ctx.Artifacts -contains $_ })
    }
    if ($indexes.Count -eq 0) { return New-Result $P.id 'index-pages-links' 'FAIL' 'no index.html matched' }
    if ($pages.Count -eq 0) { return New-Result $P.id 'index-pages-links' 'FAIL' 'no scenario pages matched' }
    $bad = @()
    foreach ($idx in $indexes) {
        $indexText = Get-FileTextSafe -Root $Ctx.Root -RelPath $idx
        foreach ($page in $pages) {
            $name = Split-Path -Leaf $page
            if ($indexText.IndexOf($name, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
                $bad += "$idx does not link $name"
            }
        }
    }
    foreach ($page in $pages) {
        $text = Get-FileTextSafe -Root $Ctx.Root -RelPath $page
        if ($text -notmatch '(?i)href="[^"]*index\.html') { $bad += "$page has no backlink to index.html" }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'index-pages-links' 'FAIL' (($bad | Select-Object -First 6) -join '; ') }
    New-Result $P.id 'index-pages-links' 'PASS' "$($indexes.Count) index, $($pages.Count) page(s)"
}

function Check-IdsUnique {
    param($P, $Ctx)
    $files = Get-FilesForParams $P $Ctx
    $rx = [regex]::new([string]$P.regex)
    $definitions = $true
    if ($null -ne $P.definitions) { $definitions = [bool]$P.definitions }
    $seen = @{}
    $dupes = @()
    foreach ($f in $files) {
        $text = Get-FileTextSafe -Root $Ctx.Root -RelPath $f
        if ($null -eq $text) { continue }
        if ($definitions) {
            foreach ($line in ($text -split "`r?`n")) {
                $lineRx = '^\s*(?:\||#{1,6}\s+|-\s*\*{0,2}|\*\*)\s*(?<id>' + $rx.ToString() + ')\b'
                $m = [regex]::Match($line, $lineRx)
                if (-not $m.Success) { continue }
                $id = $m.Groups['id'].Value
                if ($seen.ContainsKey($id)) { $dupes += "$id ($($seen[$id]), $f)" }
                else { $seen[$id] = $f }
            }
        }
        else {
            foreach ($m in $rx.Matches($text)) {
                $id = $m.Value
                if ($seen.ContainsKey($id)) { $dupes += "$id ($($seen[$id]), $f)" }
                else { $seen[$id] = $f }
            }
        }
    }
    if ($dupes.Count -gt 0) { return New-Result $P.id 'ids-unique' 'FAIL' (($dupes | Select-Object -First 6) -join '; ') }
    New-Result $P.id 'ids-unique' 'PASS' "$($seen.Count) unique id(s)"
}

function Check-IdCoverage {
    param($P, $Ctx)
    $sourceFiles = @()
    if ($P.source -eq 'card.inputs') {
        $sourceFiles = @($Ctx.Inputs | Where-Object { $_ })
    }
    elseif ($P.source -eq 'card.artifacts') {
        $sourceFiles = @($Ctx.Artifacts)
    }
    else {
        foreach ($g in @($P.source.globs)) { if ($g) { $sourceFiles += Expand-Glob -Pattern ([string]$g) -AllFiles $Ctx.AllFiles } }
    }
    $targetFiles = @()
    foreach ($g in @($P.targets.globs)) { if ($g) { $targetFiles += Expand-Glob -Pattern ([string]$g) -AllFiles $Ctx.AllFiles } }
    if ($P.scope -eq 'card') {
        $sourceFiles = @($sourceFiles | Where-Object { $Ctx.Artifacts -contains $_ })
        $targetFiles = @($targetFiles | Where-Object { $Ctx.Artifacts -contains $_ })
    }
    $sourceFiles = @($sourceFiles | Sort-Object -Unique)
    $targetFiles = @($targetFiles | Sort-Object -Unique)
    if ($sourceFiles.Count -eq 0 -or $targetFiles.Count -eq 0) {
        return New-Result $P.id 'id-coverage' 'NOT_APPLICABLE' "source=$($sourceFiles.Count), target=$($targetFiles.Count)"
    }
    $rx = [regex]::new([string]$P.regex)
    $ids = @()
    foreach ($f in $sourceFiles) {
        $text = Get-FileTextSafe -Root $Ctx.Root -RelPath $f
        if ($null -eq $text) { continue }
        foreach ($m in $rx.Matches($text)) {
            if ($ids -notcontains $m.Value) { $ids += $m.Value }
        }
    }
    $targetText = ''
    foreach ($f in $targetFiles) {
        $text = Get-FileTextSafe -Root $Ctx.Root -RelPath $f
        if ($null -ne $text) { $targetText += "`n" + $text }
    }
    $min = 1
    if ($null -ne $P.min) { $min = [int]$P.min }
    $missing = @()
    foreach ($id in $ids) {
        $count = ([regex]::Matches($targetText, [regex]::Escape($id))).Count
        if ($count -lt $min) { $missing += $id }
    }
    if ($missing.Count -gt 0) {
        return New-Result $P.id 'id-coverage' 'FAIL' ("uncovered: " + (($missing | Select-Object -First 10) -join ', '))
    }
    if ($P.strict) {
        $unknown = @()
        foreach ($m in $rx.Matches($targetText)) {
            if ($ids -notcontains $m.Value -and $unknown -notcontains $m.Value) { $unknown += $m.Value }
        }
        if ($unknown.Count -gt 0) {
            return New-Result $P.id 'id-coverage' 'FAIL' ("unknown ids: " + (($unknown | Select-Object -First 10) -join ', '))
        }
    }
    New-Result $P.id 'id-coverage' 'PASS' "$($ids.Count) id(s) covered by $($targetFiles.Count) file(s)"
}

function Check-CountMatch {
    param($P, $Ctx)
    $sourceFiles = @()
    foreach ($g in @($P.sourceGlobs)) { if ($g) { $sourceFiles += Expand-Glob -Pattern ([string]$g) -AllFiles $Ctx.AllFiles } }
    $targetFiles = @()
    foreach ($g in @($P.targetGlobs)) { if ($g) { $targetFiles += Expand-Glob -Pattern ([string]$g) -AllFiles $Ctx.AllFiles } }
    if ($P.scope -eq 'card') {
        $sourceFiles = @($sourceFiles | Where-Object { $Ctx.Artifacts -contains $_ })
        $targetFiles = @($targetFiles | Where-Object { $Ctx.Artifacts -contains $_ })
    }
    $ids = @()
    $rx = [regex]::new([string]$P.sourceRegex)
    foreach ($f in ($sourceFiles | Sort-Object -Unique)) {
        $text = Get-FileTextSafe -Root $Ctx.Root -RelPath $f
        if ($null -eq $text) { continue }
        foreach ($m in $rx.Matches($text)) { if ($ids -notcontains $m.Value) { $ids += $m.Value } }
    }
    $targetCount = @($targetFiles | Sort-Object -Unique).Count
    if ($ids.Count -eq 0) { return New-Result $P.id 'count-match' 'NOT_APPLICABLE' 'no source ids' }
    if ($ids.Count -ne $targetCount) {
        return New-Result $P.id 'count-match' 'FAIL' "ids=$($ids.Count), files=$targetCount"
    }
    New-Result $P.id 'count-match' 'PASS' "$($ids.Count) = $targetCount"
}

function Check-ReferenceCoverage {
    param($P, $Ctx)
    $sourceFiles = @()
    foreach ($g in @($P.sourceGlobs)) { if ($g) { $sourceFiles += Expand-Glob -Pattern ([string]$g) -AllFiles $Ctx.AllFiles } }
    $targetFiles = @()
    foreach ($g in @($P.targetGlobs)) { if ($g) { $targetFiles += Expand-Glob -Pattern ([string]$g) -AllFiles $Ctx.AllFiles } }
    if ($P.scope -eq 'card') {
        $sourceFiles = @($sourceFiles | Where-Object { $Ctx.Artifacts -contains $_ })
        $targetFiles = @($targetFiles | Where-Object { $Ctx.Artifacts -contains $_ })
    }
    $sourceFiles = @($sourceFiles | Sort-Object -Unique)
    $targetFiles = @($targetFiles | Sort-Object -Unique)
    if ($sourceFiles.Count -eq 0) {
        return New-Result $P.id 'reference-coverage' 'NOT_APPLICABLE' 'no source files'
    }
    if ($targetFiles.Count -eq 0) {
        return New-Result $P.id 'reference-coverage' 'FAIL' 'no target files'
    }
    $targetText = ''
    foreach ($f in $targetFiles) {
        $text = Get-FileTextSafe -Root $Ctx.Root -RelPath $f
        if ($null -ne $text) { $targetText += "`n" + $text }
    }
    $bad = @()
    foreach ($f in $sourceFiles) {
        $leaf = Split-Path -Leaf $f
        if ($targetText.IndexOf($leaf, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            $bad += $f
        }
    }
    if ($bad.Count -gt 0) {
        return New-Result $P.id 'reference-coverage' 'FAIL' ("not referenced: " + (($bad | Select-Object -First 8) -join ', '))
    }
    New-Result $P.id 'reference-coverage' 'PASS' "$($sourceFiles.Count) file(s) referenced by $($targetFiles.Count) target(s)"
}

function Check-DiffNoDelete {
    param($P, $Ctx)
    $base = [string]$P.baseCommit
    if (-not $base) { $base = [string]$Ctx.BaseCommit }
    if (-not $base -or $base -eq '-') { return New-Result $P.id 'diff-no-delete' 'NOT_APPLICABLE' 'no base commit' }
    $r = Invoke-Git -Root $Ctx.Root -Arguments @('diff', '--name-status', "$base..HEAD") -AllowFail
    if ($r.ExitCode -ne 0) { return New-Result $P.id 'diff-no-delete' 'FAIL' "git diff failed: $($r.Output -join ' ')" }
    $allowed = @($Ctx.Artifacts) + @($P.allow | Where-Object { $_ })
    $bad = @()
    foreach ($line in $r.Output) {
        $parts = ([string]$line) -split "`t"
        if ($parts.Count -lt 2) { continue }
        $status = $parts[0]
        if ($status -like 'D*') {
            if (-not (Test-GlobAny -Path $parts[1] -Patterns $allowed)) { $bad += "deleted: $($parts[1])" }
        }
        elseif ($status -like 'R*') {
            $old = $parts[1]
            $new = $parts[2]
            if (-not (Test-GlobAny -Path $old -Patterns $allowed) -and -not (Test-GlobAny -Path $new -Patterns $allowed)) {
                $bad += "renamed: $old -> $new"
            }
        }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'diff-no-delete' 'FAIL' (($bad | Select-Object -First 8) -join '; ') }
    New-Result $P.id 'diff-no-delete' 'PASS' "base $base"
}

function Check-TreeClean {
    param($P, $Ctx)
    $r = Invoke-Git -Root $Ctx.Root -Arguments @('status', '--porcelain') -AllowFail
    if ($r.ExitCode -ne 0) { return New-Result $P.id 'tree-clean' 'NOT_APPLICABLE' 'not a git repository' }
    $allowed = @($Ctx.Artifacts) + @($P.allow | Where-Object { $_ })
    $bad = @()
    foreach ($line in $r.Output) {
        $s = [string]$line
        if ($s.Length -lt 4) { continue }
        $path = $s.Substring(3).Trim()
        if ($path -match ' -> ') { $path = ($path -split ' -> ')[-1].Trim() }
        $path = $path.Trim('"').Replace('\', '/')
        if (-not (Test-GlobAny -Path $path -Patterns $allowed)) { $bad += $path }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'tree-clean' 'FAIL' ("unstaged outside allowed set: " + (($bad | Select-Object -First 8) -join ', ')) }
    New-Result $P.id 'tree-clean' 'PASS' 'tree clean within allowed set'
}

function Check-HashMatch {
    param($P, $Ctx)
    $ledger = [string]$P.ledger
    if (-not $ledger) { $ledger = "docs/evidence/$($Ctx.Task).md" }
    $ledger = $ledger.Replace('{task}', [string]$Ctx.Task)
    $full = Join-Path $Ctx.Root $ledger
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        return New-Result $P.id 'hash-match' 'NOT_APPLICABLE' "no ledger $ledger"
    }
    $text = Read-Utf8 $full
    $latest = [ordered]@{}
    foreach ($line in ($text -split "`r?`n")) {
        if ($line -notmatch '^\|') { continue }
        $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim().Trim('`') })
        for ($i = 1; $i -lt $cells.Count; $i++) {
            if ($cells[$i] -match '^[0-9a-fA-F]{64}$') {
                $latest[$cells[$i - 1].Replace('\', '/')] = $cells[$i].ToLowerInvariant()
            }
        }
    }
    if ($latest.Count -eq 0) { return New-Result $P.id 'hash-match' 'NOT_APPLICABLE' 'ledger has no hashes' }
    $bad = @()
    foreach ($path in $latest.Keys) {
        $target = Join-Path $Ctx.Root $path
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { $bad += "$path (missing)"; continue }
        $actual = Get-Sha256 $target
        if ($actual -ne $latest[$path]) { $bad += "$path (hash changed)" }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'hash-match' 'FAIL' (($bad | Select-Object -First 8) -join '; ') }
    New-Result $P.id 'hash-match' 'PASS' "$($latest.Count) artifact(s) match ledger"
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

function Check-BoardConsistency {
    param($P, $Ctx)
    if (-not $Ctx.Task) { return New-Result $P.id 'board-consistency' 'NOT_APPLICABLE' 'no task' }
    $board = Get-BoardTable -Root $Ctx.Root
    $row = $board.Rows | Where-Object { $_.id -eq $Ctx.Task } | Select-Object -First 1
    if (-not $row) { return New-Result $P.id 'board-consistency' 'FAIL' "task $($Ctx.Task) not on board" }
    $bad = @()
    if ($Ctx.Card -and $Ctx.Card['status'] -and $row.status -ne $Ctx.Card['status']) {
        $bad += "status board=$($row.status) card=$($Ctx.Card['status'])"
    }
    $cardPath = Get-CardFile -Root $Ctx.Root -Task $Ctx.Task
    if ($cardPath) {
        foreach ($cp in (Get-CardCheckpointRows -Path $cardPath)) {
            if ($cp.status -eq 'pending') { continue }
            $file = $cp['review file']
            if ($file) {
                $rel = $file.Trim('`').Replace('\', '/')
                if (-not (Test-Path -LiteralPath (Join-Path $Ctx.Root $rel))) {
                    $bad += "$($cp.id) review file missing: $rel"
                }
            }
        }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'board-consistency' 'FAIL' ($bad -join '; ') }
    New-Result $P.id 'board-consistency' 'PASS' 'board, card, checkpoints agree'
}

function Check-ActivityDerived {
    param($P, $Ctx)
    $path = Join-Path $Ctx.Root "docs\activity.puml"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return New-Result $P.id 'activity-derived' 'FAIL' 'docs/activity.puml missing'
    }
    $text = Read-Utf8 $path
    $board = Get-BoardTable -Root $Ctx.Root
    $bad = @()
    foreach ($row in $board.Rows) {
        $expected = Get-BoardStatusColor $row.status
        $line = ($text -split "`r?`n" | Where-Object { $_ -match ('^:' + [regex]::Escape($row.id) + '\s') } | Select-Object -First 1)
        if (-not $line) { $bad += "$($row.id) missing"; continue }
        $m = [regex]::Match($line, '<<#([0-9A-Fa-f]{6})>>')
        if (-not $m.Success) { $bad += "$($row.id) no color"; continue }
        if ($m.Groups[1].Value.ToUpperInvariant() -ne $expected.ToUpperInvariant()) {
            $bad += "$($row.id) color=$($m.Groups[1].Value) expected=$expected"
        }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'activity-derived' 'FAIL' (($bad | Select-Object -First 8) -join '; ') }
    New-Result $P.id 'activity-derived' 'PASS' "$($board.Rows.Count) node(s)"
}

function Check-CardFields {
    param($P, $Ctx)
    $files = @(Expand-Glob -Pattern 'docs/tasks/T-*.md' -AllFiles $Ctx.AllFiles)
    if ($P.scope -eq 'card') { $files = @($files | Where-Object { $Ctx.Artifacts -contains $_ }) }
    if ($files.Count -eq 0) { return New-Result $P.id 'card-fields' 'FAIL' 'no task cards' }
    $required = @('id', 'title', 'workflow', 'stage', 'role', 'status', 'depends_on', 'artifacts', 'e2e', 'ux')
    $bad = @()
    foreach ($f in $files) {
        $fields = Get-CardFields -Path (Join-Path $Ctx.Root $f)
        $missing = @($required | Where-Object { -not $fields.ContainsKey($_) })
        if ($missing.Count -gt 0) { $bad += "$f missing: $($missing -join ', ')" }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'card-fields' 'FAIL' (($bad | Select-Object -First 5) -join '; ') }
    New-Result $P.id 'card-fields' 'PASS' "$($files.Count) card(s)"
}

function Check-DepsAcyclic {
    param($P, $Ctx)
    $files = @(Expand-Glob -Pattern 'docs/tasks/T-*.md' -AllFiles $Ctx.AllFiles)
    $graph = @{}
    foreach ($f in $files) {
        $fields = Get-CardFields -Path (Join-Path $Ctx.Root $f)
        if (-not $fields.ContainsKey('id')) { continue }
        $id = $fields['id'].Trim('`').Trim()
        $deps = @()
        if ($fields.ContainsKey('depends_on')) {
            foreach ($d in ($fields['depends_on'] -replace '`', '').Split(',')) {
                $d = $d.Trim()
                if ($d -and $d -ne '-') { $deps += $d }
            }
        }
        $graph[$id] = $deps
    }
    $bad = @()
    foreach ($id in $graph.Keys) {
        foreach ($d in $graph[$id]) {
            if ($d -eq $id) { $bad += "$id depends on itself" }
            elseif (-not $graph.ContainsKey($d)) { $bad += "$id depends on unknown $d" }
        }
    }
    $white = @{}
    $gray = @{}
    $black = @{}
    $visit = $null
    $visit = {
        param($node)
        if ($black.ContainsKey($node)) { return $true }
        if ($gray.ContainsKey($node)) { return $false }
        $gray[$node] = $true
        foreach ($d in @($graph[$node])) {
            if ($graph.ContainsKey($d) -and -not (& $visit $d)) { return $false }
        }
        $gray.Remove($node)
        $black[$node] = $true
        $true
    }
    foreach ($id in $graph.Keys) {
        if (-not (& $visit $id)) { $bad += "cycle involving $id" }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'deps-acyclic' 'FAIL' (($bad | Select-Object -First 8) -join '; ') }
    New-Result $P.id 'deps-acyclic' 'PASS' "$($graph.Count) card(s)"
}

function Check-PythonValidator {
    param($P, $Ctx)
    $files = Get-FilesForParams $P $Ctx
    if ($files.Count -eq 0) { return New-Result $P.id 'python-validator' 'NOT_APPLICABLE' 'no files matched' }
    $script = Join-Path $Ctx.Root ([string]$P.script)
    if (-not (Test-Path -LiteralPath $script)) { return New-Result $P.id 'python-validator' 'FAIL' "validator missing: $($P.script)" }
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) { return New-Result $P.id 'python-validator' 'NOT_APPLICABLE' 'python not found' }
    $bad = @()
    foreach ($f in $files) {
        $args = @($script, (Join-Path $Ctx.Root $f))
        if ($P.useCasesGlob) {
            $md = @(Expand-Glob -Pattern ([string]$P.useCasesGlob) -AllFiles $Ctx.AllFiles) | Select-Object -First 1
            if ($md) { $args += @('--use-cases-md', (Join-Path $Ctx.Root $md)) }
        }
        $out = & $python.Source @args 2>&1
        if ($LASTEXITCODE -ne 0) { $bad += "$f : $($out -join ' ')" }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'python-validator' 'FAIL' (($bad | Select-Object -First 4) -join '; ') }
    New-Result $P.id 'python-validator' 'PASS' "$($files.Count) file(s)"
}

function Normalize-Zone {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    $t = $Text.ToLowerInvariant()
    $t = [regex]::Replace($t, '[^0-9a-z]+', ' ')
    return ($t.Trim() -replace '\s+', ' ')
}

function Split-MarkdownRow {
    param([string]$Line)
    $t = ([string]$Line).Trim()
    if ($t.StartsWith('|')) { $t = $t.Substring(1) }
    if ($t.EndsWith('|')) { $t = $t.Substring(0, $t.Length - 1) }
    return @($t -split '\|' | ForEach-Object { $_.Trim() })
}

function Get-MarkdownTables {
    param([string]$Text)
    if ($null -eq $Text) { return @() }
    $lines = $Text -split "`r?`n"
    $tables = @()
    $i = 0
    while ($i -lt $lines.Count) {
        if ($lines[$i] -match '^\s*\|.*\|\s*$') {
            $header = Split-MarkdownRow $lines[$i]
            $rows = @()
            $j = $i + 1
            while ($j -lt $lines.Count -and $lines[$j] -match '^\s*\|.*\|\s*$') {
                $cells = Split-MarkdownRow $lines[$j]
                $isSeparator = $true
                foreach ($c in $cells) { if ($c -notmatch '^:?-{2,}:?$') { $isSeparator = $false; break } }
                if (-not $isSeparator -and $cells.Count -gt 0) { $rows += , $cells }
                $j++
            }
            $tables += [pscustomobject]@{ Header = @($header); Rows = @($rows) }
            $i = $j
        }
        else { $i++ }
    }
    return $tables
}

function Get-SectionLines {
    param([string[]]$Lines, [string]$Heading)
    $start = -1
    $level = 0
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match ('^\s*(#+)\s*' + [regex]::Escape($Heading) + '\s*$')) {
            $start = $i
            $level = $Matches[1].Length
            break
        }
    }
    if ($start -lt 0) { return $null }
    $end = $Lines.Count
    for ($i = $start + 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\s*(#+)\s+\S') {
            if ($Matches[1].Length -le $level) { $end = $i; break }
        }
    }
    if ($end -le ($start + 1)) { return @() }
    return @($Lines[($start + 1)..($end - 1)])
}

function Get-ZoneLevelRows {
    param([string[]]$SectionLines, [string]$Level, [string]$Alt = '')
    $subs = @{}
    $current = $null
    $buf = @()
    foreach ($l in @($SectionLines)) {
        if ($l -match '^\s*###\s+(.+?)\s*$') {
            if ($null -ne $current) { $subs[$current] = ($buf -join "`n") }
            $current = $Matches[1]
            $buf = @()
        }
        else { $buf += $l }
    }
    if ($null -ne $current) { $subs[$current] = ($buf -join "`n") }
    foreach ($k in @($subs.Keys)) {
        $heading = $k.ToLowerInvariant()
        if ($heading.Contains($Level.ToLowerInvariant()) -or ($Alt -and $heading.Contains($Alt.ToLowerInvariant()))) {
            return [pscustomobject]@{ Found = $true; Body = [string]$subs[$k] }
        }
    }
    return [pscustomobject]@{ Found = $false; Body = '' }
}

function Check-ZonesUnique {
    param($P, $Ctx)
    $files = Get-FilesForParams $P $Ctx
    if ($files.Count -eq 0) { return New-Result $P.id 'zones-unique' 'NOT_APPLICABLE' 'no files matched' }
    $levels = @($P.levels | Where-Object { $_ })
    if ($levels.Count -eq 0) { $levels = @('components', 'modules', 'classes') }
    $heading = if ($P.heading) { [string]$P.heading } else { 'Responsibility zones' }
    $bad = @()
    $zoneCount = 0
    foreach ($f in $files) {
        $text = Get-FileTextSafe -Root $Ctx.Root -RelPath $f
        if ($null -eq $text) { $bad += "$f (missing)"; continue }
        $lines = $text -split "`r?`n"
        $section = Get-SectionLines -Lines $lines -Heading $heading
        if ($null -eq $section) { $bad += "$f missing '## $heading' section"; continue }

        $componentNames = @()
        $componentsSection = Get-SectionLines -Lines $lines -Heading 'Components'
        if ($null -ne $componentsSection) {
            $ctables = Get-MarkdownTables ($componentsSection -join "`n")
            if ($ctables.Count -gt 0) {
                foreach ($r in @($ctables[0].Rows)) {
                    if ($r.Count -gt 0 -and ($r[0]).Trim()) { $componentNames += ($r[0]).Trim() }
                }
            }
        }

        $levelZones = @{}
        foreach ($level in $levels) {
            $singular = if ($level -match 'ses$') { $level.Substring(0, $level.Length - 2) } else { $level.TrimEnd('s') }
            $sub = Get-ZoneLevelRows -SectionLines $section -Level $level -Alt $singular
            $waiverRx = '(?im)^[\s>*`]*No\s+' + $singular + 's?\b'
            $hasWaiver = if ($sub.Found) { [bool]($sub.Body -match $waiverRx) } else { [bool]($text -match $waiverRx) }
            if (-not $sub.Found) {
                if ($hasWaiver) { continue }
                $bad += "$f missing '${level}' zone table and no waiver statement"
                continue
            }

            $tables = Get-MarkdownTables $sub.Body
            $table = $null
            foreach ($t in @($tables)) {
                $h = ($t.Header -join ' ').ToLowerInvariant()
                if ($h -match 'owns' -and $h -match 'does not own') { $table = $t; break }
            }
            if ($null -eq $table -or @($table.Rows).Count -eq 0) {
                if ($hasWaiver) { continue }
                if ($null -eq $table) { $bad += "$f missing zone table with 'Owns' and 'Does not own' columns ($level)" }
                else { $bad += "$f empty '${level}' zone table and no waiver statement" }
                continue
            }

            $header = @($table.Header)
            $idxOwns = -1; $idxNotOwns = -1; $idxParent = -1; $idxId = -1
            for ($c = 0; $c -lt $header.Count; $c++) {
                $h = ([string]$header[$c]).ToLowerInvariant()
                if ($h -match 'does not own') { $idxNotOwns = $c }
                elseif ($h -match 'owns') { if ($idxOwns -lt 0) { $idxOwns = $c } }
                if ($h -match 'parent') { $idxParent = $c }
                if ($h -match '^(id|component|module|class)\b') { if ($idxId -lt 0) { $idxId = $c } }
            }
            if ($idxOwns -lt 0 -or $idxNotOwns -lt 0) {
                $bad += "$f zone table needs 'Owns' and 'Does not own' columns ($level)"
                continue
            }

            $zones = @()
            $ids = @{}
            foreach ($row in @($table.Rows)) {
                $id = if ($idxId -ge 0 -and $row.Count -gt $idxId) { ([string]$row[$idxId]).Trim() } else { '' }
                $owns = if ($row.Count -gt $idxOwns) { ([string]$row[$idxOwns]).Trim() } else { '' }
                $notOwns = if ($row.Count -gt $idxNotOwns) { ([string]$row[$idxNotOwns]).Trim() } else { '' }
                $parent = if ($idxParent -ge 0 -and $row.Count -gt $idxParent) { ([string]$row[$idxParent]).Trim() } else { '' }
                if (-not $id) { $bad += "$f ${level}: row without an id or name"; continue }
                if (-not $owns) { $bad += "$f $level '$id': empty 'Owns'"; continue }
                if (-not $notOwns) { $bad += "$f $level '$id': empty 'Does not own'"; continue }
                if ($ids.ContainsKey($id)) { $bad += "$f ${level}: duplicate id '$id'" }
                else { $ids[$id] = $true }
                $zones += [pscustomobject]@{
                    Id      = $id
                    Owns    = $owns
                    NotOwns = $notOwns
                    Parent  = $parent
                    Key     = (Normalize-Zone $owns)
                }
            }
            $zoneCount += $zones.Count
            $levelZones[$level] = $zones

            $seen = @{}
            foreach ($z in $zones) {
                $k = "$level|$($z.Parent)|$($z.Key)"
                if ($seen.ContainsKey($k)) { $bad += "$f ${level}: duplicated zone '$($z.Owns)' in '$($z.Id)' and '$($seen[$k])'" }
                else { $seen[$k] = $z.Id }
            }
            foreach ($a in $zones) {
                foreach ($b in $zones) {
                    if ($a.Id -eq $b.Id) { continue }
                    if ($a.Parent -ne $b.Parent) { continue }
                    $na = $a.Key
                    $nb = (Normalize-Zone $b.NotOwns)
                    if ($na.Length -ge 8 -and $nb.Contains($na)) {
                        $bad += "$f ${level}: '$($b.Id)' excludes '$($a.Owns)' that '$($a.Id)' owns"
                    }
                }
            }
        }

        $componentZones = @()
        if ($levelZones.ContainsKey('components')) { $componentZones = @($levelZones['components']) }
        if ($levelZones.ContainsKey('components') -and $componentNames.Count -gt 0) {
            $cmpLower = @($componentNames | ForEach-Object { $_.ToLowerInvariant() })
            foreach ($z in $componentZones) {
                if ($cmpLower -notcontains $z.Id.ToLowerInvariant()) {
                    $bad += "${f}: component '$($z.Id)' is not listed in the '## Components' table"
                }
            }
            $zoneLower = @($componentZones | ForEach-Object { $_.Id.ToLowerInvariant() })
            foreach ($n in $componentNames) {
                if ($zoneLower -notcontains $n.ToLowerInvariant()) {
                    $bad += "${f}: component '$n' has no responsibility zone"
                }
            }
        }

        $moduleIds = @()
        if ($levelZones.ContainsKey('modules')) {
            foreach ($z in @($levelZones['modules'])) { $moduleIds += $z.Id }
        }
        $componentIds = @($componentZones | ForEach-Object { $_.Id })
        foreach ($level in $levels) {
            if (-not $levelZones.ContainsKey($level)) { continue }
            if ($level -eq 'components') { continue }
            foreach ($z in @($levelZones[$level])) {
                if (-not $z.Parent) { $bad += "$f $level '$($z.Id)': empty parent"; continue }
                if ($level -eq 'modules') {
                    if (@($componentIds | Where-Object { $_ -eq $z.Parent }).Count -eq 0) {
                        $bad += "$f modules '$($z.Id)': unknown parent component '$($z.Parent)'"
                    }
                }
                else {
                    $ok = (@($moduleIds | Where-Object { $_ -eq $z.Parent }).Count -gt 0) -or
                        (@($componentIds | Where-Object { $_ -eq $z.Parent }).Count -gt 0) -or
                        ($z.Parent.ToLowerInvariant() -eq 'application')
                    if (-not $ok) { $bad += "$f $level '$($z.Id)': unknown parent '$($z.Parent)'" }
                }
            }
        }
    }
    if ($bad.Count -gt 0) { return New-Result $P.id 'zones-unique' 'FAIL' (($bad | Select-Object -First 8) -join '; ') }
    New-Result $P.id 'zones-unique' 'PASS' "$($files.Count) file(s), $zoneCount zone(s)"
}

function Invoke-Check {

    param($Def, $Ctx)
    $id = [string]$Def.id
    $type = [string]$Def.type
    $P = @{ id = $id }
    if ($Def.params -is [hashtable]) {
        foreach ($k in $Def.params.Keys) { $P[$k] = $Def.params[$k] }
    }
    elseif ($null -ne $Def.params) {
        foreach ($prop in $Def.params.PSObject.Properties) { $P[$prop.Name] = $prop.Value }
    }
    try {
        switch ($type) {
            'file-exists' { return Check-FileExists $P $Ctx }
            'pattern-absent' { return Check-Pattern -P $P -Ctx $Ctx -Absent }
            'pattern-present' { return Check-Pattern -P $P -Ctx $Ctx }
            'headings-required' { return Check-Headings $P $Ctx }
            'puml-syntax' { return Check-PumlSyntax $P $Ctx }
            'svg-fresh' { return Check-SvgFresh $P $Ctx }
            'html-structure' { return Check-HtmlStructure $P $Ctx }
            'html-links-exist' { return Check-HtmlLinks $P $Ctx }
            'index-pages-links' { return Check-IndexPages $P $Ctx }
            'ids-unique' { return Check-IdsUnique $P $Ctx }
            'id-coverage' { return Check-IdCoverage $P $Ctx }
            'count-match' { return Check-CountMatch $P $Ctx }
            'reference-coverage' { return Check-ReferenceCoverage $P $Ctx }
            'diff-no-delete' { return Check-DiffNoDelete $P $Ctx }
            'tree-clean' { return Check-TreeClean $P $Ctx }
            'hash-match' { return Check-HashMatch $P $Ctx }
            'board-consistency' { return Check-BoardConsistency $P $Ctx }
            'activity-derived' { return Check-ActivityDerived $P $Ctx }
            'card-fields' { return Check-CardFields $P $Ctx }
            'deps-acyclic' { return Check-DepsAcyclic $P $Ctx }
            'python-validator' { return Check-PythonValidator $P $Ctx }
            'zones-unique' { return Check-ZonesUnique $P $Ctx }
            'manual' {
                $reason = if ($P.reason) { [string]$P.reason } else { 'semantic review' }
                return New-Result $id 'manual' 'MANUAL' $reason
            }
            default { return New-Result $id $type 'FAIL' "unknown check type '$type'" }
        }
    }
    catch {
        New-Result $id $type 'FAIL' "engine error: $($_.Exception.Message)"
    }
}

function Assert-Equal {
    param([string]$Label, [string]$Actual, [string]$Expected, [ref]$Failed)
    if ($Actual -eq $Expected) {
        Write-Host ("[ok]   {0}: {1}" -f $Label, $Actual) -ForegroundColor Green
    }
    else {
        Write-Host ("[FAIL] {0}: expected {1}, got {2}" -f $Label, $Expected, $Actual) -ForegroundColor Red
        $Failed.Value = $true
    }
}

function Invoke-SelfTest {
    Write-Host "verify-artifacts self-test" -ForegroundColor Cyan
    $failed = $false
    $base = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-selftest-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $base | Out-Null

    function New-CaseDir {
        param([string]$Name)
        $d = Join-Path $base $Name
        New-Item -ItemType Directory -Force -Path $d | Out-Null
        $d
    }
    function New-TextFile {
        param([string]$Dir, [string]$Rel, [string]$Text)
        $p = Join-Path $Dir $Rel
        Write-Utf8NoBom $p $Text
    }
    function Invoke-Case {
        param([string]$Name, [string]$Type, [hashtable]$Params, [string]$Dir, [string]$Expect)
        $all = @(Get-AllFiles -Root $Dir)
        $ctx = @{
            Root       = $Dir
            AllFiles   = $all
            Artifacts  = @()
            Inputs     = @()
            Unresolved = @()
            Task       = 'T-999'
            Stage      = 'X'
            Workflow   = 'feature'
            Card       = @{ status = 'in_progress' }
            BaseCommit = $null
        }
        $def = [pscustomobject]@{ id = $Name; type = $Type; params = [pscustomobject]$Params }
        $r = Invoke-Check -Def $def -Ctx $ctx
        Assert-Equal -Label $Name -Actual $r.result -Expected $Expect -Failed ([ref]$failed)
    }

    try {
        $d = New-CaseDir 'file-exists-bad'
        $null = New-CaseDir 'file-exists-bad/docs/empty'
        Invoke-Case -Name 'file-exists missing' -Type 'file-exists' -Params @{ globs = @('docs/*.md'); minCount = 1 } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'pattern-absent-bad'
        New-TextFile $d 'p/index.html' '<html><script src="https://cdn.example/x.js"></script></html>'
        Invoke-Case -Name 'pattern-absent cdn' -Type 'pattern-absent' -Params @{ globs = @('p/*.html'); patterns = @('https://', 'fetch(') } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'headings-bad'
        New-TextFile $d 'docs/a.md' "# A`n`n## Other`n`ntext"
        Invoke-Case -Name 'headings-required missing' -Type 'headings-required' -Params @{ glob = 'docs/*.md'; headings = @('## Required') } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'ids-bad'
        New-TextFile $d 'docs/r.md' "| R-001 | one |`n| R-001 | two |"
        Invoke-Case -Name 'ids-unique duplicate' -Type 'ids-unique' -Params @{ glob = 'docs/*.md'; regex = 'R-\d{3}'; definitions = $true } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'coverage-bad'
        New-TextFile $d 'docs/uc.md' 'UC-E2E-001 UC-E2E-002'
        New-TextFile $d 'docs/spec.md' 'UC-E2E-001 only'
        Invoke-Case -Name 'id-coverage missing' -Type 'id-coverage' -Params @{ source = @{ globs = @('docs/uc.md') }; targets = @{ globs = @('docs/spec.md') }; regex = 'UC-E2E-\d{3}' } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'count-bad'
        New-TextFile $d 'docs/uc.md' 'UC-E2E-001 UC-E2E-002 UC-E2E-003'
        New-TextFile $d 'p/uc-e2e-001.html' 'x'
        New-TextFile $d 'p/uc-e2e-002.html' 'x'
        Invoke-Case -Name 'count-match mismatch' -Type 'count-match' -Params @{ sourceGlobs = @('docs/uc.md'); sourceRegex = 'UC-E2E-\d{3}'; targetGlobs = @('p/uc-e2e-*.html') } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'reference-bad'
        New-TextFile $d 'docs/architecture/architecture-x.md' 'See components-a.puml only.'
        New-TextFile $d 'docs/architecture/components-a.puml' '@startuml`n@enduml'
        New-TextFile $d 'docs/architecture/sequence-scn-001.puml' '@startuml`n@enduml'
        Invoke-Case -Name 'reference-coverage missing' -Type 'reference-coverage' -Params @{ sourceGlobs = @('docs/architecture/components-*.puml', 'docs/architecture/sequence-*.puml'); targetGlobs = @('docs/architecture/architecture-*.md') } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'reference-good'
        New-TextFile $d 'docs/architecture/architecture-x.md' 'See components-a.puml and sequence-scn-001.puml.'
        New-TextFile $d 'docs/architecture/components-a.puml' '@startuml`n@enduml'
        New-TextFile $d 'docs/architecture/sequence-scn-001.puml' '@startuml`n@enduml'
        Invoke-Case -Name 'reference-coverage present' -Type 'reference-coverage' -Params @{ sourceGlobs = @('docs/architecture/components-*.puml', 'docs/architecture/sequence-*.puml'); targetGlobs = @('docs/architecture/architecture-*.md') } -Dir $d -Expect 'PASS'

        $d = New-CaseDir 'puml-bad'
        New-TextFile $d 'd/a.puml' '@startuml`nA -> B`n'
        Invoke-Case -Name 'puml-syntax missing end' -Type 'puml-syntax' -Params @{ glob = 'd/*.puml' } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'html-bad'
        New-TextFile $d 'p/a.html' '<html><head><title>X</title></head><body>'
        Invoke-Case -Name 'html-structure unclosed' -Type 'html-structure' -Params @{ globs = @('p/*.html'); lang = 'ru' } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'links-bad'
        New-TextFile $d 'p/index.html' '<html><a href="missing.html">x</a></html>'
        Invoke-Case -Name 'html-links-exist broken' -Type 'html-links-exist' -Params @{ glob = 'p/*.html' } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'index-bad'
        New-TextFile $d 'p/index.html' '<html>catalog</html>'
        New-TextFile $d 'p/uc-e2e-001.html' '<html>page</html>'
        Invoke-Case -Name 'index-pages-links missing' -Type 'index-pages-links' -Params @{ indexGlobs = @('p/index.html'); pagesGlobs = @('p/uc-e2e-*.html') } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'hash-bad'
        New-TextFile $d 'a.md' 'content'
        New-TextFile $d 'docs/evidence/T-999.md' "| Artifact | SHA256 |`n|---|---|`n| a.md | $('0' * 64) |"
        Invoke-Case -Name 'hash-match changed' -Type 'hash-match' -Params @{ ledger = 'docs/evidence/{task}.md' } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'diff-bad'
        $null = Invoke-Git -Root $d -Arguments @('init', '-q')
        $null = Invoke-Git -Root $d -Arguments @('-c', 'user.email=t@t', '-c', 'user.name=t', 'add', '-A')
        New-TextFile $d 'keep.txt' 'keep'
        New-TextFile $d 'delete.txt' 'delete'
        $null = Invoke-Git -Root $d -Arguments @('add', '-A')
        $null = Invoke-Git -Root $d -Arguments @('-c', 'user.email=t@t', '-c', 'user.name=t', 'commit', '-qm', 'base')
        $baseCommit = ([string]((Invoke-Git -Root $d -Arguments @('rev-parse', 'HEAD')).Output[0])).Trim()
        Remove-Item -LiteralPath (Join-Path $d 'delete.txt') -Force
        $null = Invoke-Git -Root $d -Arguments @('add', '-A')
        $null = Invoke-Git -Root $d -Arguments @('-c', 'user.email=t@t', '-c', 'user.name=t', 'commit', '-qm', 'drop')
        $all = @(Get-AllFiles -Root $d)
        $ctx = @{ Root = $d; AllFiles = $all; Artifacts = @('keep.txt'); Inputs = @(); Task = 'T-999'; Stage = 'X'; Card = @{}; BaseCommit = $baseCommit; Workflow = 'feature' }
        $def = [pscustomobject]@{ id = 'diff-no-delete deletion'; type = 'diff-no-delete'; params = [pscustomobject]@{ allow = @('keep.txt') } }
        $r = Invoke-Check -Def $def -Ctx $ctx
        Assert-Equal -Label 'diff-no-delete deletion' -Actual $r.result -Expected 'FAIL' -Failed ([ref]$failed)

        $d = New-CaseDir 'tree-bad'
        $null = Invoke-Git -Root $d -Arguments @('init', '-q')
        New-TextFile $d 'tracked.txt' 'x'
        $null = Invoke-Git -Root $d -Arguments @('add', '-A')
        $null = Invoke-Git -Root $d -Arguments @('-c', 'user.email=t@t', '-c', 'user.name=t', 'commit', '-qm', 'base')
        New-TextFile $d 'stray.txt' 'y'
        Invoke-Case -Name 'tree-clean stray' -Type 'tree-clean' -Params @{ allow = @('tracked.txt') } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'sanity-good'
        New-TextFile $d 'docs/a.md' "# A`n`n## Required`n`ntext"
        New-TextFile $d 'p/index.html' '<html lang="ru"><head><title>X</title></head><body><a href="uc-e2e-001.html">1</a></body></html>'
        New-TextFile $d 'p/uc-e2e-001.html' '<html lang="ru"><head><title>P</title></head><body><a href="index.html">back</a></body></html>'
        Invoke-Case -Name 'sanity headings pass' -Type 'headings-required' -Params @{ glob = 'docs/*.md'; headings = @('## Required') } -Dir $d -Expect 'PASS'
        Invoke-Case -Name 'sanity index pass' -Type 'index-pages-links' -Params @{ indexGlobs = @('p/index.html'); pagesGlobs = @('p/uc-e2e-*.html') } -Dir $d -Expect 'PASS'

        $zoneDoc = @(
            '# Architecture',
            '',
            '## Components',
            '',
            '| Component | Responsibility | Interfaces | Depends on |',
            '|---|---|---|---|',
            '| Api | http | rest | - |',
            '| Core | domain | - | - |',
            '',
            '## Responsibility zones',
            '',
            '### Components',
            '',
            '| Component | Owns (zone) | Does not own | Depends on |',
            '|---|---|---|---|',
            '| Api | http transport and request routing | business rules | - |',
            '| Core | business rules and persistence | http transport | - |',
            '',
            '### Modules',
            '',
            '| ID | Module | Parent component | Owns (zone) | Does not own | Depends on |',
            '|---|---|---|---|---|---|',
            '| MOD-001 | http | Api | request parsing and routing | domain validation | - |',
            '',
            '### Classes',
            '',
            '| ID | Class | Parent module / application | Owns (zone) | Does not own | Depends on |',
            '|---|---|---|---|---|---|',
            '| CLS-001 | Request | MOD-001 | request parsing | business rules | - |'
        ) -join "`n"

        $d = New-CaseDir 'zones-good'
        New-TextFile $d 'docs/architecture/architecture-x.md' $zoneDoc
        Invoke-Case -Name 'zones-unique valid' -Type 'zones-unique' -Params @{ globs = @('docs/architecture/architecture-*.md'); levels = @('components', 'modules', 'classes') } -Dir $d -Expect 'PASS'

        $d = New-CaseDir 'zones-missing-section'
        New-TextFile $d 'docs/architecture/architecture-x.md' "# Architecture`n`n## Components`n`n| Component | Responsibility |`n|---|---|`n| Api | http |"
        Invoke-Case -Name 'zones-unique missing section' -Type 'zones-unique' -Params @{ globs = @('docs/architecture/architecture-*.md') } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'zones-duplicate'
        New-TextFile $d 'docs/architecture/architecture-x.md' ($zoneDoc -replace '\| Api \| http transport and request routing \|', '| Api | business rules and persistence |')
        Invoke-Case -Name 'zones-unique duplicate zone' -Type 'zones-unique' -Params @{ globs = @('docs/architecture/architecture-*.md'); levels = @('components') } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'zones-empty'
        New-TextFile $d 'docs/architecture/architecture-x.md' ($zoneDoc -replace '\| Api \| http transport and request routing \| business rules \|', '| Api |  | business rules |')
        Invoke-Case -Name 'zones-unique empty owns' -Type 'zones-unique' -Params @{ globs = @('docs/architecture/architecture-*.md'); levels = @('components') } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'zones-contradiction'
        New-TextFile $d 'docs/architecture/architecture-x.md' ($zoneDoc -replace '\| Core \| business rules and persistence \| http transport \|', '| Core | business rules and persistence | http transport and request routing |')
        Invoke-Case -Name 'zones-unique contradiction' -Type 'zones-unique' -Params @{ globs = @('docs/architecture/architecture-*.md'); levels = @('components') } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'zones-parent'
        New-TextFile $d 'docs/architecture/architecture-x.md' ($zoneDoc -replace '\| MOD-001 \| http \| Api \|', '| MOD-001 | http | Missing |')
        Invoke-Case -Name 'zones-unique unknown parent' -Type 'zones-unique' -Params @{ globs = @('docs/architecture/architecture-*.md'); levels = @('components', 'modules') } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'zones-waived'
        $waivedDoc = @(
            '# Architecture',
            '',
            '## Components',
            '',
            '| Component | Responsibility |',
            '|---|---|',
            '| Api | http |',
            '',
            '## Responsibility zones',
            '',
            '### Components',
            '',
            '| Component | Owns (zone) | Does not own |',
            '|---|---|---|',
            '| Api | http transport | business rules |',
            '',
            '### Modules',
            '',
            'No module decomposition (single component solution)'
        ) -join "`n"
        New-TextFile $d 'docs/architecture/architecture-x.md' $waivedDoc
        Invoke-Case -Name 'zones-unique waived modules' -Type 'zones-unique' -Params @{ globs = @('docs/architecture/architecture-*.md'); levels = @('components', 'modules') } -Dir $d -Expect 'PASS'

        $d = New-CaseDir 'zones-missing-level'
        New-TextFile $d 'docs/architecture/architecture-x.md' ($zoneDoc -replace '(?s)### Modules.*?### Classes', '### Classes')
        Invoke-Case -Name 'zones-unique missing level' -Type 'zones-unique' -Params @{ globs = @('docs/architecture/architecture-*.md'); levels = @('components', 'modules') } -Dir $d -Expect 'FAIL'

        $d = New-CaseDir 'zones-waiver-with-table'
        $mixedDoc = @(
            '# Architecture',
            '',
            '## Components',
            '',
            '| Component | Responsibility |',
            '|---|---|',
            '| Api | http |',
            '',
            '## Responsibility zones',
            '',
            '### Components',
            '',
            '| Component | Owns (zone) | Does not own |',
            '|---|---|---|',
            '| Api | http transport | business rules |',
            '',
            '### Modules',
            '',
            'No module decomposition (placeholder text left in the template)',
            '',
            '| ID | Module | Parent component | Owns (zone) | Does not own |',
            '|---|---|---|---|---|',
            '| MOD-001 |  |  |  |  |'
        ) -join "`n"
        New-TextFile $d 'docs/architecture/architecture-x.md' $mixedDoc
        Invoke-Case -Name 'zones-unique waiver with unfilled table' -Type 'zones-unique' -Params @{ globs = @('docs/architecture/architecture-*.md'); levels = @('components', 'modules') } -Dir $d -Expect 'FAIL'
    }
    finally {
        Remove-Item -LiteralPath $base -Recurse -Force -ErrorAction SilentlyContinue
    }
    if ($failed) {
        Write-Host "SELF-TEST FAILED" -ForegroundColor Red
        return 1
    }
    Write-Host "SELF-TEST PASSED" -ForegroundColor Green
    return 0
}

if ($SelfTest) {
    exit (Invoke-SelfTest)
}

if (-not $Root) { $Root = Get-HarnessRoot }
$Root = (Resolve-Path -LiteralPath $Root).Path
$registryDir = if ($ChecksDir) { $ChecksDir } else { Join-Path $Root "harness\checks" }
if (-not $ChecksDir -and -not (Test-Path -LiteralPath $registryDir)) {
    $localChecks = Join-Path (Split-Path -Parent $PSScriptRoot) "checks"
    if (Test-Path -LiteralPath $localChecks) {
        Write-Host "[warn] $Root has no harness/checks; using $localChecks" -ForegroundColor Yellow
        $registryDir = $localChecks
    }
}
if (-not (Test-Path -LiteralPath $registryDir)) {
    Write-Host "[err] checks registry not found: $registryDir" -ForegroundColor Red
    exit 2
}

$card = @{}
$cardPath = $null
if ($Task) {
    $cardPath = Get-CardFile -Root $Root -Task $Task
    if (-not $cardPath) {
        Write-Host "[err] task card not found for $Task" -ForegroundColor Red
        exit 2
    }
    $card = Get-CardFields -Path $cardPath
    if ($Workflow -eq 'auto' -and $card.ContainsKey('workflow')) { $Workflow = $card['workflow'].Trim().ToLowerInvariant() }
    if (-not $Stage -and $card.ContainsKey('stage')) { $Stage = ($card['stage'] -split '/')[0].Trim() }
}
if ($Workflow -eq 'auto') { $Workflow = 'feature' }
if (-not $Stage) {
    Write-Host "[err] -Stage is required when the card has no stage" -ForegroundColor Red
    exit 2
}

$enginePath = Join-Path $registryDir "engine.json"
$workflowPath = Join-Path $registryDir "$Workflow.json"
foreach ($p in @($enginePath, $workflowPath)) {
    if (-not (Test-Path -LiteralPath $p)) {
        Write-Host "[err] registry file missing: $p" -ForegroundColor Red
        exit 2
    }
}
$engine = Read-Utf8 $enginePath | ConvertFrom-Json
$registry = Read-Utf8 $workflowPath | ConvertFrom-Json
$stageNode = $registry.stages.PSObject.Properties[$Stage]
if (-not $stageNode) {
    Write-Host "[err] stage '$Stage' is not defined in $workflowPath" -ForegroundColor Red
    exit 2
}
$stageDef = $stageNode.Value

if ($List) {
    Write-Host "workflow: $Workflow  stage: $Stage"
    Write-Host ""
    Write-Host "universal:"
    foreach ($c in @($engine.universal)) { Write-Host ("  {0,-28} {1}" -f $c.id, $c.type) }
    Write-Host ""
    Write-Host "stage:"
    foreach ($c in @($stageDef.checks)) { Write-Host ("  {0,-28} {1}" -f $c.id, $c.type) }
    exit 0
}

$allFiles = @(Get-AllFiles -Root $Root)
$declared = Expand-Artifacts -Items @($card['artifacts']) -AllFiles $allFiles -Root $Root
$artifacts = @($declared.Files)
$declaredInputs = Expand-Artifacts -Items @($card['inputs']) -AllFiles $allFiles -Root $Root
$inputs = @($declaredInputs.Files)
$baseCommit = Get-TaskBaseCommit -Root $Root -Card $card -Task $Task

$ctx = @{
    Root       = $Root
    AllFiles   = $allFiles
    Artifacts  = $artifacts
    Inputs     = $inputs
    Unresolved = @($declared.Unresolved)
    Task       = $Task
    Stage      = $Stage
    Workflow   = $Workflow
    Card       = $card
    BaseCommit = $baseCommit
}

$defs = @()
foreach ($c in @($engine.universal)) { $defs += $c }
foreach ($c in @($stageDef.checks)) { $defs += $c }
if ($Check) { $defs = @($defs | Where-Object { $_.id -eq $Check }) }
if ($defs.Count -eq 0) {
    Write-Host "[err] no checks selected" -ForegroundColor Red
    exit 2
}

$results = @()
foreach ($def in $defs) {
    $params = $def.params
    $paramsJson = $params | ConvertTo-Json -Depth 8 -Compress
    $resolved = $paramsJson.Replace('{task}', [string]$Task)
    $params = $resolved | ConvertFrom-Json
    $r = Invoke-Check -Def ([pscustomobject]@{ id = $def.id; type = $def.type; params = $params }) -Ctx $ctx
    $results += $r
}

$covered = @{}
foreach ($def in $defs) {
    $p = $def.params
    foreach ($key in @('globs', 'glob', 'pagesGlobs', 'indexGlobs', 'sourceGlobs', 'targetGlobs')) {
        foreach ($g in @($p.$key)) { if ($g) { $covered[[string]$g] = $true } }
    }
    if ($p.source -eq 'card.artifacts') { foreach ($a in $artifacts) { $covered[$a] = $true } }
}
$unchecked = @()
foreach ($a in $artifacts) {
    $hit = $false
    foreach ($g in $covered.Keys) {
        if ($a -match (ConvertTo-GlobRegex ([string]$g))) { $hit = $true; break }
    }
    if (-not $hit) { $unchecked += $a }
}

$pass = @($results | Where-Object { $_.result -eq 'PASS' }).Count
$fail = @($results | Where-Object { $_.result -eq 'FAIL' }).Count
$manual = @($results | Where-Object { $_.result -eq 'MANUAL' }).Count
$na = @($results | Where-Object { $_.result -eq 'NOT_APPLICABLE' }).Count

$width = 30
foreach ($r in $results) { if ($r.id.Length + 2 -gt $width) { $width = $r.id.Length + 2 } }
foreach ($r in $results) {
    $color = switch ($r.result) {
        'PASS' { 'Green' }
        'FAIL' { 'Red' }
        'MANUAL' { 'Yellow' }
        default { 'Gray' }
    }
    Write-Host ("[{0,-16}] {1,-$width} {2}" -f $r.result, $r.id, $r.detail) -ForegroundColor $color
}
Write-Host ""
Write-Host ("RESULT: {0} PASS, {1} FAIL, {2} MANUAL, {3} N/A, {4} UNCHECKED" -f $pass, $fail, $manual, $na, $unchecked.Count)
if ($unchecked.Count -gt 0) {
    Write-Host "UNCHECKED artifacts:" -ForegroundColor Yellow
    foreach ($u in $unchecked) { Write-Host "  $u" -ForegroundColor Yellow }
}

if ($Json) {
    $payload = [pscustomobject]@{
        task        = $Task
        workflow    = $Workflow
        stage       = $Stage
        root        = $Root
        base_commit = $baseCommit
        generated_at = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
        results     = $results
        summary     = [pscustomobject]@{ pass = $pass; fail = $fail; manual = $manual; not_applicable = $na; unchecked = $unchecked.Count }
        unchecked   = $unchecked
    }
    $jsonPath = if ([System.IO.Path]::IsPathRooted($Json)) { $Json } else { Join-Path $Root $Json }
    Write-Utf8NoBom $jsonPath ($payload | ConvertTo-Json -Depth 8)
    Write-Host "JSON: $jsonPath"
}

if ($fail -gt 0) { exit 1 }
if ($unchecked.Count -gt 0) {
    if ($WarnOnly) { exit 0 }
    exit 2
}
exit 0
