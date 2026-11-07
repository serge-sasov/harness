#requires -Version 5.1
<#
.SYNOPSIS
  Проверка глобальной установки harness и текущего проекта.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$script:critical = $false

function Write-Ok($text) { Write-Host "[ok]   $text" -ForegroundColor Green }
function Write-Warn($text) { Write-Host "[warn] $text" -ForegroundColor Yellow }
function Write-Err($text) { Write-Host "[err]  $text" -ForegroundColor Red; $script:critical = $true }

$UserProfile = [Environment]::GetFolderPath("UserProfile")
$GlobalRoot = Join-Path $UserProfile ".config\opencode"
$GlobalHarness = Join-Path $GlobalRoot "harness"
$Project = (Get-Location).Path

Write-Host "Harness doctor"
Write-Host "  user:    $UserProfile"
Write-Host "  project: $Project"
Write-Host ""

$globalFiles = @(
    (Join-Path $GlobalRoot "agents\harness.md"),
    (Join-Path $GlobalRoot "agents\harness-orchestrator.md"),
    (Join-Path $GlobalRoot "agents\harness-analyst.md"),
    (Join-Path $GlobalRoot "agents\harness-architect.md"),
    (Join-Path $GlobalRoot "agents\harness-coder.md"),
    (Join-Path $GlobalRoot "agents\harness-qa.md"),
    (Join-Path $GlobalRoot "agents\harness-doc-writer.md"),
    (Join-Path $GlobalRoot "commands\harness-init.md"),
    (Join-Path $GlobalRoot "commands\harness-run.md"),
    (Join-Path $GlobalRoot "commands\harness-board-update.md"),
    (Join-Path $GlobalRoot "commands\harness-board-report.md"),
    (Join-Path $GlobalRoot "commands\harness-doctor.md"),
    (Join-Path $GlobalRoot "skills\harness\SKILL.md"),
    (Join-Path $GlobalHarness "process.md"),
    (Join-Path $GlobalHarness "version.json"),
    (Join-Path $GlobalHarness "templates\task-card.md"),
    (Join-Path $GlobalHarness "templates\adr.md"),
    (Join-Path $GlobalHarness "templates\plan-row.md")
)
$missingGlobal = @()
foreach ($file in $globalFiles) {
    if (-not (Test-Path -LiteralPath $file)) { $missingGlobal += $file }
}
if ($missingGlobal.Count -eq 0) {
    Write-Ok "глобальные агенты, команды, skill и шаблоны на месте"
}
else {
    Write-Err "не хватает глобальных файлов harness:"
    $missingGlobal | ForEach-Object { Write-Host "       $_" }
}

$configPath = Join-Path $GlobalRoot "opencode.jsonc"
$harnessIds = @(
    "harness-orchestrator",
    "harness-analyst",
    "harness-architect",
    "harness-coder",
    "harness-qa",
    "harness-doc-writer"
)
if (Test-Path -LiteralPath $configPath) {
    $config = Get-Content -LiteralPath $configPath -Raw
    if ($config -match '"task"\s*:') {
        $notAllowed = @($harnessIds | Where-Object {
            $config -notmatch ('"' + [regex]::Escape($_) + '"\s*:\s*"allow"')
        })
        if ($notAllowed.Count -eq 0) {
            Write-Ok "permission.task разрешает все harness-роли"
        }
        else {
            Write-Warn "permission.task не даёт allow для: $($notAllowed -join ', ')"
        }
    }
    else {
        Write-Warn "в opencode.jsonc нет блока permission.task; выполните install.ps1 для явных allow-правил"
    }
    if ($config -match '"plantuml-render"') { Write-Ok "MCP plantuml-render настроен" } else { Write-Warn "MCP plantuml-render не найден в конфиге" }
    if ($config -match '"local-rag"') { Write-Ok "MCP local-rag настроен" } else { Write-Warn "MCP local-rag не найден в конфиге" }
    if ($config -match 'qwen3\.8:27b-64k') { Write-Ok "модель qwen3.8:27b-64k объявлена" } else { Write-Warn "модель qwen3.8:27b-64k не найдена в конфиге" }
    if ($config -match 'tiel-coder:35b-a3b-mtp-128k-text') { Write-Ok "модель tiel-coder text объявлена" } else { Write-Warn "модель tiel-coder text не найдена в конфиге" }
    if ($config -match 'tiel-coder:35b-a3b-mtp-128k-vision') { Write-Ok "модель tiel-coder vision объявлена" } else { Write-Warn "модель tiel-coder vision не найдена в конфиге" }
}
else {
    Write-Warn "не найден $configPath; allow-правила harness не настроены"
}

$marker = Join-Path $Project "harness\process.md"
$plan = Join-Path $Project "docs\plan.md"
$projectVersionPath = Join-Path $Project "harness\version.json"
if ((Test-Path -LiteralPath $marker) -and (Test-Path -LiteralPath $plan)) {
    Write-Ok "проект инициализирован как harness"
    if (Test-Path -LiteralPath $projectVersionPath) {
        try {
            $globalVersion = Get-Content -LiteralPath (Join-Path $GlobalHarness "version.json") -Raw | ConvertFrom-Json
            $projectVersion = Get-Content -LiteralPath $projectVersionPath -Raw | ConvertFrom-Json
            if ($globalVersion.version -eq $projectVersion.version) {
                Write-Ok "версия проекта совпадает с глобальной ($($projectVersion.version))"
            }
            else {
                Write-Warn "версия проекта $($projectVersion.version) отличается от глобальной $($globalVersion.version)"
            }
        }
        catch {
            Write-Warn "не удалось прочитать версии: $_"
        }
    }
    else {
        Write-Warn "нет harness/version.json; выполните /harness-init -Force или добавьте файл"
    }
}
else {
    Write-Warn "текущий проект не инициализирован: нет harness/process.md или docs/plan.md; выполните /harness-init"
}

$oldIds = @("analyst.md", "architect.md", "coder.md", "qa.md", "doc-writer.md", "orchestrator.md")
$oldFiles = @()
foreach ($name in $oldIds) {
    $path = Join-Path $Project ".opencode\agents\$name"
    if (Test-Path -LiteralPath $path) { $oldFiles += $path }
}
if ($oldFiles.Count -eq 0) {
    Write-Ok "в проекте нет старых копий агентов с ID без префикса harness-"
}
else {
    Write-Warn "найдены старые проектные копии агентов (могут обходить gating):"
    $oldFiles | ForEach-Object { Write-Host "       $_" }
}

if (Get-Command opencode -ErrorAction SilentlyContinue) { Write-Ok "opencode найден в PATH" } else { Write-Warn "opencode не найден в PATH" }
if (Get-Command ollama -ErrorAction SilentlyContinue) { Write-Ok "ollama найден в PATH" } else { Write-Warn "ollama не найден в PATH; проверьте локальные модели" }

Write-Host ""
if ($script:critical) {
    Write-Host "Итог: есть критические проблемы установки harness." -ForegroundColor Red
    exit 1
}
Write-Host "Итог: критических проблем нет; проверьте предупреждения выше." -ForegroundColor Green
exit 0
