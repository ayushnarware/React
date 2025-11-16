# push_built_to_ghpages.ps1
# Run from repo root in PowerShell (VS Code).
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Starting push of built outputs to gh-pages..." -ForegroundColor Cyan

# repo & remote
$remoteUrl = git remote get-url origin 2>$null
if (-not $remoteUrl) {
    Write-Error "No remote 'origin' found."
    exit 1
}
$repoName = [IO.Path]::GetFileNameWithoutExtension($remoteUrl)

Write-Host "Repo detected: $repoName"

# ensure .git exists
if (-not (Test-Path ".git")) {
    Write-Error "Run this from repo root (no .git found)"
    exit 1
}

# clean old gh-pages
if (Test-Path "gh-pages") {
    Remove-Item -Recurse -Force "gh-pages"
}

# check if gh-pages branch exists remotely
$branch = git ls-remote --heads origin gh-pages 2>$null

if ($branch) {
    Write-Host "Cloning gh-pages..."
    git clone --depth 1 --branch gh-pages $remoteUrl gh-pages
} else {
    Write-Host "No gh-pages found. Creating local folder..."
    New-Item -ItemType Directory -Path gh-pages | Out-Null
    Push-Location gh-pages
    git init
    git remote add origin $remoteUrl
    Pop-Location
}

# empty gh-pages folder
Get-ChildItem gh-pages -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# copy build/dist outputs
$copied = @()

foreach ($dir in Get-ChildItem -Directory | Where-Object { $_.Name -notin @('.github','gh-pages') }) {
    $folder = $dir.Name
    $full = $dir.FullName
    $build = Join-Path $full "build"
    $dist  = Join-Path $full "dist"

    if (Test-Path $build -or Test-Path $dist) {
        Write-Host "Copying $folder..."
        New-Item -ItemType Directory -Force -Path ("gh-pages/$folder") | Out-Null

        if (Test-Path $build) { Copy-Item "$build\*" "gh-pages\$folder" -Recurse -Force }
        if (Test-Path $dist)  { Copy-Item "$dist\*"  "gh-pages\$folder" -Recurse -Force }

        $copied += $folder
    }
}

if ($copied.Count -eq 0) {
    Write-Error "No built outputs found. Build projects first."
    exit 1
}

# make index.html
$index = @()
$index += "<!DOCTYPE html>"
$index += "<html><body><h1>Projects</h1><ul>"

foreach ($p in $copied) {
    $index += "<li><a href='./$p/'>$p</a></li>"
}

$index += "</ul></body></html>"
$index -join "`n" | Out-File -FilePath "gh-pages/index.html" -Encoding utf8

# commit + push
Push-Location gh-pages
git add .
git config user.email "actions@github.com"
git config user.name "Auto Deploy"
try { git commit -m ("deploy " + (Get-Date).ToString("u")) 2>$null } catch {}
git branch -M gh-pages
git push origin gh-pages --force
Pop-Location

Write-Host "`nDONE! Open: https://ayushnarware.github.io/$repoName/" -ForegroundColor Green
