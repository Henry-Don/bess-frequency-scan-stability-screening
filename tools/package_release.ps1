$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $projectRoot "VERSION") -Raw).Trim()
$archiveName = "bess-frequency-scan-stability-screening-v$version.zip"
$outputDirectory = Join-Path $projectRoot "dist"
$outputPath = Join-Path $outputDirectory $archiveName
$archivePrefix = "bess-frequency-scan-stability-screening-v$version/"

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

git -C $projectRoot diff --quiet
if ($LASTEXITCODE -ne 0) {
    throw "Commit or stash tracked changes before creating a release archive."
}

git -C $projectRoot diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    throw "Commit or unstage staged changes before creating a release archive."
}

git -C $projectRoot archive `
    --format=zip `
    --prefix=$archivePrefix `
    --output=$outputPath `
    HEAD

if ($LASTEXITCODE -ne 0) {
    throw "Release archive creation failed."
}

Write-Host "Created $outputPath"
