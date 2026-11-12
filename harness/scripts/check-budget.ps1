#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
    [string[]]$Path,
    [ValidateSet("md", "yaml", "code")]
    [string]$Kind = "md",
    [double]$MaxWriteKb = 0,
    [double]$MaxSessionKb = 0,
    [switch]$Session,
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

if ($MaxWriteKb -le 0) {
    $MaxWriteKb = switch ($Kind) {
        "md" { 8 }
        "yaml" { 6 }
        "code" { 12 }
    }
}
if ($MaxSessionKb -le 0) {
    $MaxSessionKb = switch ($Kind) {
        "md" { 20 }
        "yaml" { 15 }
        "code" { 40 }
    }
}

$totalBytes = 0
$failed = $false
foreach ($item in $Path) {
    if (-not (Test-Path -LiteralPath $item -PathType Leaf)) {
        Write-Host "[FAIL] $item : not found"
        $failed = $true
        continue
    }
    $file = Get-Item -LiteralPath $item
    $kb = [math]::Round($file.Length / 1KB, 1)
    $totalBytes += $file.Length
    $lines = (Get-Content -LiteralPath $item | Measure-Object -Line).Lines
    if ($kb -gt $MaxWriteKb) {
        $message = "[WARN] $item : $kb KB > per-write $MaxWriteKb KB; author incrementally"
        if ($Strict) { $message = $message.Replace("[WARN]", "[FAIL]"); $failed = $true }
        Write-Host $message
    }
    else {
        Write-Host "[OK]   $item : $kb KB, $lines lines"
    }
}

if ($Session -and $Path.Count -gt 0) {
    $totalKb = [math]::Round($totalBytes / 1KB, 1)
    if ($totalKb -gt $MaxSessionKb) {
        Write-Host "[FAIL] session total ${totalKb} KB > $MaxSessionKb KB; split the stage"
        $failed = $true
    }
    else {
        Write-Host "[OK]   session total $totalKb KB <= $MaxSessionKb KB"
    }
}

if ($failed) { exit 1 }
exit 0
