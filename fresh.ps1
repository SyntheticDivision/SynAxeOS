$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = "C:\Projects\SynAxeOS"

if (Test-Path -LiteralPath $dest) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $bakName = "SynAxeOS-old-$stamp"
    Write-Host "Moving the old $dest aside to C:\Projects\$bakName"
    Rename-Item -LiteralPath $dest -NewName $bakName
}

Write-Host "Cloning a clean ESP-Miner v2.14.2 into $dest"
& git clone --branch v2.14.2 --depth 1 https://github.com/bitaxeorg/ESP-Miner.git $dest
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Push-Location $dest
& git submodule update --init --recursive
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    exit $LASTEXITCODE
}
Pop-Location

if (-not (Test-Path (Join-Path $dest "CMakeLists.txt"))) {
    Write-Host "The clone did not produce a firmware tree."
    exit 1
}

$patch = Join-Path $dest "SynAxeOS"
New-Item -ItemType Directory -Force -Path $patch | Out-Null
foreach ($name in @("install.ps1", "build.ps1", "flash.ps1", "fresh.ps1", "build-synaxe.js", "README.md", "INSTALL.md", "LICENSE")) {
    $src = Join-Path $here $name
    if (Test-Path $src) {
        Copy-Item -Force $src (Join-Path $patch $name)
    }
}
Copy-Item -Recurse -Force (Join-Path $here "synaxe-www") (Join-Path $patch "synaxe-www")

Write-Host "Patching the clean tree"
Set-Location $patch
& powershell -ExecutionPolicy Bypass -File .\install.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$tps = Join-Path $dest "main\power\TPS546.c"
$tpsText = [System.IO.File]::ReadAllText($tps)
if ($tpsText -notlike "*TPS546 fixed window*") {
    Write-Host "The fresh tree is missing the fixed TPS546 window."
    exit 1
}
if ($tpsText -like "*VOUT window command*") {
    Write-Host "The old rejected window is still in the fresh tree."
    exit 1
}

Write-Host ""
Write-Host "Fresh SynAxe OS is at $dest"
Write-Host "The old C:\Projects\SynAxe OS tree was not used."
Write-Host "Build and flash this one:"
Write-Host "  cd `"$dest\SynAxeOS`""
Write-Host "  powershell -ExecutionPolicy Bypass -File .\build.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\flash.ps1"
Write-Host "The boot log must say: TPS546 fixed window ov_fault"
