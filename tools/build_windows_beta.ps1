param(
    [string]$Godot = "godot",
    [string]$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")),
    [string]$OutputDir = ""
)
$ErrorActionPreference = "Stop"
$project = (Resolve-Path $ProjectPath).Path
$projectConfig = Get-Content (Join-Path $project "project.godot") -Raw
if ($projectConfig -notmatch 'config/version="([^"]+)"') { throw "Could not read application version from project.godot" }
$version = $Matches[1]
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $project "build\v$version-windows"
}
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$exe = Join-Path $OutputDir "Beat_UP_v$version.exe"
Write-Host "Running release gate for Beat UP! v$version"
& $Godot --headless --editor --path $project --import
if ($LASTEXITCODE -ne 0) { throw "Godot import/parser check failed with exit code $LASTEXITCODE" }
Write-Host "Exporting Beat UP! v$version from $project"
& $Godot --headless --path $project --export-release "Windows Desktop" $exe
if ($LASTEXITCODE -ne 0) { throw "Godot export failed with exit code $LASTEXITCODE" }
Copy-Item (Join-Path $project "qa\BETA_TESTING_GUIDE.md") (Join-Path $OutputDir "BETA_TESTING_GUIDE.md") -Force
Write-Host "Windows beta created at $OutputDir"
