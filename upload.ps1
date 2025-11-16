Write-Host "Cleaning gh-pages..."
if (Test-Path gh-pages) { Remove-Item gh-pages -Recurse -Force }

Write-Host "Cloning gh-pages branch..."
git clone --depth 1 --branch gh-pages (git remote get-url origin) gh-pages

Write-Host "Clearing old files..."
Get-ChildItem gh-pages -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Copying ALL dist/build outputs..."

foreach ($dir in Get-ChildItem -Directory) {
    $name = $dir.Name

    if ($name -in ".github","gh-pages","React Routing") {
        continue
    }

    $build = Join-Path $dir.FullName "build"
    $dist  = Join-Path $dir.FullName "dist"

    if (Test-Path $build) {
        Write-Host "→ $name (build/)"
        New-Item -Path "gh-pages/$name" -ItemType Directory -Force | Out-Null
        Copy-Item "$build/*" "gh-pages/$name" -Recurse -Force
    }
    elseif (Test-Path $dist) {
        Write-Host "→ $name (dist/)"
        New-Item -Path "gh-pages/$name" -ItemType Directory -Force | Out-Null
        Copy-Item "$dist/*" "gh-pages/$name" -Recurse -Force
    }
}

Write-Host "Generating index.html..."

$index = @("<h1>Projects</h1><ul>")
foreach ($folder in Get-ChildItem -Path "gh-pages" -Directory) {
    $index += "<li><a href='./$folder/'>$folder</a></li>"
}
$index += "</ul>"
$index -join "`n" | Out-File "gh-pages/index.html" -Encoding UTF8

Write-Host "Pushing to GitHub Pages..."
cd gh-pages
git add .
git commit -m "deploy all" 2>$null
git push origin gh-pages --force
cd ..

Write-Host "DONE"
