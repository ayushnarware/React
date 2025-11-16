# ===========================
# Automatic Multi-React Deploy (Windows PowerShell)
# ===========================

Write-Host "🚀 Multi-React Auto Deploy started..."

# Detect repo name
$remoteUrl = git remote get-url origin
$repoName = ($remoteUrl.Split('/')[-1]).Replace(".git", "")
Write-Host "Repo detected: $repoName"

# Loop through subfolders
$folders = Get-ChildItem -Directory

foreach ($folder in $folders) {
    $folderPath = $folder.FullName
    $project = $folder.Name

    # Skip .github or gh-pages
    if ($project -eq ".github" -or $project -eq "gh-pages") {
        continue
    }

    # Check package.json
    if (-Not (Test-Path "$folderPath\package.json")) {
        Write-Host "⏭️ Skipping $project (no package.json)"
        continue
    }

    Write-Host "`n📦 Installing dependencies for $project ..."
    npm ci --prefix $folderPath

    # Detect Vite
    $isVite = Select-String -Path "$folderPath\package.json" -Pattern '"vite"' -Quiet

    if ($isVite) {
        Write-Host "🟣 Vite project detected: $project"
        npx vite build --cwd $folderPath --base "/$repoName/$project/"
    }
    else {
        Write-Host "🔵 CRA project detected: $project"
        $env:PUBLIC_URL = "/$repoName/$project"
        npm run build --prefix $folderPath
        Remove-Item env:PUBLIC_URL -ErrorAction SilentlyContinue
    }
}

# ===========================
# Prepare gh-pages folder
# ===========================

Write-Host "`n📂 Preparing gh-pages branch..."

if (Test-Path "gh-pages") {
    Remove-Item -Recurse -Force "gh-pages"
}

# Clone gh-pages if exists
$branchExists = git ls-remote --heads origin gh-pages

if ($branchExists) {
    git clone --depth 1 --branch gh-pages $remoteUrl gh-pages
} else {
    mkdir gh-pages | Out-Null
    cd gh-pages
    git init
    git remote add origin $remoteUrl
    cd ..
}

# Clear old contents
Remove-Item -Recurse -Force "gh-pages\*" -ErrorAction SilentlyContinue

# ===========================
# Copy build/dist into gh-pages
# ===========================

$folders = Get-ChildItem -Directory

foreach ($folder in $folders) {
    $folderPath = $folder.FullName
    $project = $folder.Name

    # CRA build
    if (Test-Path "$folderPath\build") {
        Write-Host "📤 Copying CRA build: $project"
        New-Item -ItemType Directory -Path "gh-pages\$project" -Force | Out-Null
        Copy-Item "$folderPath\build\*" "gh-pages\$project" -Recurse -Force
    }

    # Vite dist
    if (Test-Path "$folderPath\dist") {
        Write-Host "📤 Copying Vite dist: $project"
        New-Item -ItemType Directory -Path "gh-pages\$project" -Force | Out-Null
        Copy-Item "$folderPath\dist\*" "gh-pages\$project" -Recurse -Force
    }
}

# ===========================
# Create index.html
# ===========================

Write-Host "📝 Creating index.html..."

$index = @"
<!doctype html>
<html>
<head>
  <meta charset='utf-8'>
  <title>Projects</title>
</head>
<body>
  <h1>Projects</h1>
"@

$projects = Get-ChildItem "gh-pages" -Directory

foreach ($p in $projects) {
    $name = $p.Name
    $index += "<a href='./$name/'>$name</a><br/>`n"
}

$index += "</body></html>"

Set-Content -Path "gh-pages/index.html" -Value $index

# ===========================
# Commit & Push to gh-pages
# ===========================

Write-Host "`n🚀 Pushing to gh-pages..."

cd gh-pages
git add .
git commit -m "Auto Deploy" 2>$null
git branch -M gh-pages
git push origin gh-pages --force
cd ..

Write-Host "`n✅ Deployment complete!"
