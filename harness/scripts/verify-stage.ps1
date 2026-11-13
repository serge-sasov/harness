#requires -Version 5.1
<#
.SYNOPSIS
Convenience wrapper around verify-artifacts.ps1 for a workflow stage.
#>
[CmdletBinding()]
param(
    [string]$Task,
    [string]$Stage,
    [string]$Root = '',
    [string]$ChecksDir = '',
    [string]$Json,
    [string]$Check,
    [switch]$List,
    [switch]$WarnOnly
)

$ErrorActionPreference = "Stop"
$target = Join-Path $PSScriptRoot "verify-artifacts.ps1"
$arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $target)
if ($Task) { $arguments += @('-Task', $Task) }
if ($Stage) { $arguments += @('-Stage', $Stage) }
if ($Root) { $arguments += @('-Root', $Root) }
if ($ChecksDir) { $arguments += @('-ChecksDir', $ChecksDir) }
if ($Json) { $arguments += @('-Json', $Json) }
if ($Check) { $arguments += @('-Check', $Check) }
if ($List) { $arguments += @('-List') }
if ($WarnOnly) { $arguments += @('-WarnOnly') }

& powershell @arguments
exit $LASTEXITCODE
