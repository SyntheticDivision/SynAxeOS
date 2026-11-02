$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$parent = Split-Path -Parent $here
if (Test-Path (Join-Path $parent "CMakeLists.txt")) {
    $root = $parent
} else {
    $root = "C:\Projects\SynAxeOS"
}
if (-not (Test-Path (Join-Path $root "CMakeLists.txt"))) {
    Write-Host "Run fresh.ps1 first. $root is not a clean ESP-Miner tree."
    exit 1
}
Set-Location $root
idf.py set-target esp32s3
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
idf.py build
exit $LASTEXITCODE
