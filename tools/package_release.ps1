$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$projectName = "bess-frequency-scan-stability-screening"
$versionTag = (Get-Content -LiteralPath (Join-Path $projectRoot "VERSION") -Raw).Trim()
if ($versionTag -notmatch '^v\d+\.\d+\.\d+$') {
    throw "VERSION must use the vMAJOR.MINOR.PATCH format."
}

$archiveName = "$projectName-$versionTag.zip"
$outputDirectory = Join-Path $projectRoot "dist"
$outputPath = Join-Path $outputDirectory $archiveName
$checksumPath = "$outputPath.sha256"
$archivePrefix = "$projectName-$versionTag/"

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

git -c "safe.directory=$projectRoot" -C $projectRoot diff --quiet
if ($LASTEXITCODE -ne 0) {
    throw "Commit or stash tracked changes before creating a release archive."
}

git -c "safe.directory=$projectRoot" -C $projectRoot diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    throw "Commit or unstage staged changes before creating a release archive."
}

$headCommit = (git -c "safe.directory=$projectRoot" -C $projectRoot rev-parse HEAD).Trim()
$tagCommit = (git -c "safe.directory=$projectRoot" -C $projectRoot rev-list -n 1 $versionTag).Trim()
if (-not $tagCommit) {
    throw "The local tag $versionTag does not exist."
}
if ($headCommit -ne $tagCommit) {
    throw "The local tag $versionTag must point to HEAD before packaging."
}

git -c "safe.directory=$projectRoot" -C $projectRoot archive `
    --format=zip `
    --prefix=$archivePrefix `
    --output=$outputPath `
    $versionTag

if ($LASTEXITCODE -ne 0) {
    throw "Release archive creation failed."
}

$hash = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath $checksumPath -Value "$hash  $archiveName" -Encoding ascii

Write-Host "Created $outputPath"
Write-Host "Created $checksumPath"
