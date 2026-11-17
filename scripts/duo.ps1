# Version Windows de duo.sh : 1 agent builder + 1 agent reviewer, chacun dans son worktree,
# ouverts dans deux onglets Windows Terminal (ou deux fenêtres PowerShell si wt est absent).
#
#   .\scripts\duo.ps1                         # les deux sur Sonnet (recommandé sur Pro)
#   .\scripts\duo.ps1 -BuilderModel opus      # builder sur Opus pour une tâche difficile
#
# Prérequis : Git for Windows (fournit Git Bash), GitHub CLI (gh), Claude Code.
param(
    [string]$BuilderModel = "sonnet",
    [string]$ReviewerModel = "sonnet"
)
$ErrorActionPreference = "Stop"

foreach ($bin in "git", "gh", "claude") {
    if (-not (Get-Command $bin -ErrorAction SilentlyContinue)) {
        Write-Host "Outil manquant : $bin (voir README > Installation sous Windows)" -ForegroundColor Red
        exit 1
    }
}

# Git Bash, pour lancer reviewer-watch.sh
$bash = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $bash) {
    Write-Host "Git Bash introuvable : installe Git for Windows (winget install Git.Git)" -ForegroundColor Red
    exit 1
}

$root  = (git rev-parse --show-toplevel).Trim() -replace "/", "\"
$repo  = Split-Path $root -Leaf
$wtDir = Join-Path (Split-Path $root -Parent) "$repo-worktrees"
New-Item -ItemType Directory -Force -Path $wtDir | Out-Null
git -C $root fetch --quiet origin 2>$null

foreach ($name in "builder", "reviewer") {
    $path = Join-Path $wtDir $name
    if (-not (Test-Path $path)) {
        git -C $root worktree add --detach $path origin/main 2>$null
        if ($LASTEXITCODE -ne 0) { git -C $root worktree add --detach $path main }
    }
    if ((Test-Path "$root\.env") -and -not (Test-Path "$path\.env")) {
        Copy-Item "$root\.env" "$path\.env"
    }
}

$builderDir  = Join-Path $wtDir "builder"
$reviewerDir = Join-Path $wtDir "reviewer"
$builderCmd  = "claude --model $BuilderModel /next"
$watchScript = ($root -replace "\\", "/") + "/scripts/reviewer-watch.sh"

if (Get-Command wt -ErrorAction SilentlyContinue) {
    wt new-tab --title builder -d "$builderDir" powershell -NoExit -Command $builderCmd `; `
       new-tab --title reviewer -d "$reviewerDir" "$bash" -lc "REVIEWER_MODEL=$ReviewerModel '$watchScript'"
} else {
    Start-Process powershell -WorkingDirectory $builderDir -ArgumentList "-NoExit", "-Command", $builderCmd
    Start-Process $bash -WorkingDirectory $reviewerDir -ArgumentList "-lc", "REVIEWER_MODEL=$ReviewerModel '$watchScript'"
}

Write-Host "✔ duo lancé (builder: $BuilderModel, reviewer: $ReviewerModel)" -ForegroundColor Green
Write-Host "  Fermer les deux onglets pour arrêter."
