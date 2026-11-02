$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$parent = Split-Path -Parent $here
if (Test-Path (Join-Path $parent "CMakeLists.txt")) {
    $root = $parent
} else {
    $root = "C:\Projects\SynAxeOS"
}
$Port = "COM9"
if ($args.Count -ge 1 -and $args[0]) { $Port = $args[0] }
if (-not (Test-Path (Join-Path $root "CMakeLists.txt"))) {
    Write-Host "Run fresh.ps1 and build.ps1 first."
    exit 1
}
Set-Location $root
idf.py -p $Port flash
exit $LASTEXITCODE
