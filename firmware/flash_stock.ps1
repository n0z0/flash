# Flash stock Nokia 6.1 Plus (DRG) 00WW_4_10C - OS partitions only.
# Bootloader/secure partitions (xbl, abl, tz, hyp, rpm, keymaster, cmnlib*, devcfg, pmic)
# are intentionally skipped to avoid anti-rollback bricks.
$ErrorActionPreference = 'Stop'
Set-Location "$PSScriptRoot\images"
$parts = 'boot','modem','dsp','bluetooth','cda','hidden','nvdef','splash','systeminfo','vendor','system'
foreach ($slot in 'a','b') {
    foreach ($p in $parts) {
        Write-Host "==> flashing ${p}_${slot}"
        fastboot flash "${p}_${slot}" "$p.img"
        if ($LASTEXITCODE -ne 0) { throw "Failed: ${p}_${slot}" }
    }
}
Write-Host "==> wiping userdata"
fastboot -w
if ($LASTEXITCODE -ne 0) { throw "wipe failed" }
Write-Host "==> reboot"
fastboot reboot
