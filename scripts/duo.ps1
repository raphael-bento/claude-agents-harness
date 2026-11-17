# Windows version of duo.sh: 1 builder agent + 1 reviewer agent, each in its own git worktree,
# opened in two Windows Terminal tabs (or two separate windows if wt is missing).
#
#   .\scripts\duo.ps1                         # both on Sonnet (recommended on Pro)
#   .\scripts\duo.ps1 -BuilderModel opus      # builder on Opus for a hard task
#
# Requirements: Git for Windows (Git Bash), GitHub CLI (gh), Claude Code.
# NOTE: keep this file ASCII-only. Windows PowerShell 5.1 misreads UTF-8 accents.
param(
    [string]$BuilderModel = "sonnet",
    [string]$ReviewerModel = "sonnet"
)
# "Continue", not "Stop": git writes normal progress messages to stderr,
# which Windows PowerShell 5.1 would otherwise turn into fatal errors.
$ErrorActionPreference = "Continue"

foreach ($bin in "git", "gh", "claude") {
    if (-not (Get-Command $bin -ErrorAction SilentlyContinue)) {
        Write-Host "Missing tool: $bin (see README > Installation sous Windows)" -ForegroundColor Red
        exit 1
    }
}

$bash = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $bash) {
    Write-Host "Git Bash not found: install Git for Windows (winget install Git.Git)" -ForegroundColor Red
    exit 1
}

$root = (git rev-parse --show-toplevel)
if ($LASTEXITCODE -ne 0) { Write-Host "Run this script from inside the repo." -ForegroundColor Red; exit 1 }
$root  = $root.Trim() -replace "/", "\"
$repo  = Split-Path $root -Leaf
$wtDir = Join-Path (Split-Path $root -Parent) "$repo-worktrees"
New-Item -ItemType Directory -Force -Path $wtDir | Out-Null
git -C $root fetch --quiet origin 2>&1 | Out-Null

foreach ($name in "builder", "reviewer") {
    $path = Join-Path $wtDir $name
    if (-not (Test-Path $path)) {
        git -C $root worktree add --detach $path origin/main 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { git -C $root worktree add --detach $path main 2>&1 | Out-Null }
        if ($LASTEXITCODE -ne 0) { Write-Host "Could not create worktree $path" -ForegroundColor Red; exit 1 }
    }
    if ((Test-Path "$root\.env") -and -not (Test-Path "$path\.env")) {
        Copy-Item "$root\.env" "$path\.env"
    }
    Write-Host "[ok] worktree $name -> $path"
}

$builderDir    = Join-Path $wtDir "builder"
$reviewerDir   = Join-Path $wtDir "reviewer"
$builderCmd    = "claude --model $BuilderModel /next"
$watchScript   = ($root -replace "\\", "/") + "/scripts/reviewer-watch.sh"
$reviewerPosix = $reviewerDir -replace "\\", "/"
$reviewerCmd   = "cd '$reviewerPosix' && REVIEWER_MODEL=$ReviewerModel bash '$watchScript'"

if (Get-Command wt -ErrorAction SilentlyContinue) {
    wt new-tab --title builder -d "$builderDir" powershell -NoExit -Command $builderCmd `; `
       new-tab --title reviewer -d "$reviewerDir" "$bash" -c "$reviewerCmd"
} else {
    Start-Process powershell -WorkingDirectory $builderDir -ArgumentList "-NoExit", "-Command", $builderCmd
    Start-Process $bash -WorkingDirectory $reviewerDir -ArgumentList "-c", "`"$reviewerCmd`""
}

Write-Host "[ok] duo started (builder: $BuilderModel, reviewer: $ReviewerModel)" -ForegroundColor Green
Write-Host "     Close both tabs to stop."
