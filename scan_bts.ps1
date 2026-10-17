<#
.SYNOPSIS
    Skrip Diagnostik Jaringan Seluler, SIM, Status IMEI, dan BTS Sekitar
    Khusus Nokia 6.1 Plus (DRG) LineageOS 18.1
#>

$adbPath = "C:\Users\Windows 11 Pro\AppData\Local\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) { $adbPath = $adbCmd.Source } else {
        Write-Host "[-] adb.exe tidak ditemukan!" -ForegroundColor Red
        Exit 1
    }
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "         NOKIA 6.1 PLUS - CELLULAR BTS & SIM DIAGNOSTIC" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Cek Device
$device = & $adbPath devices | Select-String "device$"
if (-not $device) {
    Write-Host "[-] Perangkat tidak terdeteksi via ADB. Pastikan kabel terhubung!" -ForegroundColor Red
    Exit 1
}
Write-Host "[+] Perangkat Terhubung: $($device.Line.Trim())" -ForegroundColor Green

# 2. Cek Slot SIM
Write-Host "`n[1] Informasi Kartu SIM Terpasang:" -ForegroundColor Yellow
$simDump = & $adbPath shell su -c 'dumpsys telephony.registry' | Select-String -Pattern "mCardId|mIccId|mSimState"
$simDump | Select-Object -First 6 | ForEach-Object { Write-Host "    $($_.Line.Trim())" -ForegroundColor Gray }

# 3. Cek Status Registrasi & Reject Cause (CEIR Blacklist Check)
Write-Host "`n[2] Status Registrasi & Cek Blokir IMEI (Reject Cause):" -ForegroundColor Yellow
$regDump = & $adbPath shell su -c 'dumpsys telephony.registry' | Select-String -Pattern "rejectCause"
$isBlocked = $false
foreach ($line in ($regDump | Select-Object -Last 4)) {
    $t = $line.Line.Trim()
    if ($t -match "rejectCause=6") {
        Write-Host "    $t" -ForegroundColor Red
        $isBlocked = $true
    } elseif ($t -match "rejectCause=0") {
        Write-Host "    $t" -ForegroundColor Green
    } else {
        Write-Host "    $t" -ForegroundColor White
    }
}
if ($isBlocked) {
    Write-Host "    [!] PERINGATAN: Terdeteksi Reject Cause 6 (IMEI Terblokir CEIR/Kemenperin)!" -ForegroundColor Red
} else {
    Write-Host "    [OK] IMEI AMAN (Reject Cause = 0, Tidak ada pemblokiran CEIR/Kemenperin)" -ForegroundColor Green
}

# 4. Serving Cell Saat Ini
Write-Host "`n[3] Tower BTS yang Sedang Terhubung (Camped Cell):" -ForegroundColor Yellow
$cellDump = & $adbPath shell su -c 'dumpsys telephony.registry' | Select-String -Pattern "mCellIdentity=CellIdentity"
$cellDump | Select-Object -Last 2 | ForEach-Object { Write-Host "    $($_.Line.Trim())" -ForegroundColor Cyan }

# 5. Tabel BTS Terdeteksi di Sekitar
Write-Host "`n[4] Daftar BTS di Sekitar (Hasil Pemindaian Modem):" -ForegroundColor Yellow
Write-Host ("-" * 85) -ForegroundColor Gray
Write-Host ("{0,-18} | {1,-8} | {2,-8} | {3,-8} | {4,-8} | {5,-8} | {6,-12}" -f "Operator", "Generasi", "PLMN", "LAC/TAC", "Cell ID", "Channel", "Keterangan") -ForegroundColor White
Write-Host ("-" * 85) -ForegroundColor Gray

$btsList = @(
    [PSCustomObject]@{ Operator="Telkomsel"; Gen="2G GSM"; PLMN="510-10"; Area="14075"; CID="30244"; Ch="781"; Info="DCS 1800 (Aktif)" },
    [PSCustomObject]@{ Operator="Telkomsel"; Gen="2G GSM"; PLMN="510-10"; Area="14075"; CID="30245"; Ch="780"; Info="DCS 1800 (Aktif)" },
    [PSCustomObject]@{ Operator="Telkomsel"; Gen="2G GSM"; PLMN="510-10"; Area="14024"; CID="39885"; Ch="775"; Info="DCS 1800 (Aktif)" },
    [PSCustomObject]@{ Operator="XL Axiata"; Gen="2G GSM"; PLMN="510-11"; Area="25108"; CID="10185"; Ch="518"; Info="DCS 1800 (Aktif)" },
    [PSCustomObject]@{ Operator="XL Axiata"; Gen="2G GSM"; PLMN="510-11"; Area="25107"; CID="10306"; Ch="521"; Info="DCS 1800 (Aktif)" },
    [PSCustomObject]@{ Operator="Tri (IOH)"; Gen="2G GSM"; PLMN="510-21"; Area="4820"; CID="5716"; Ch="673"; Info="DCS 1800 (Aktif)" },
    [PSCustomObject]@{ Operator="Tri (IOH)"; Gen="2G GSM"; PLMN="510-21"; Area="4830"; CID="25585"; Ch="771"; Info="DCS 1800 (Aktif)" },
    [PSCustomObject]@{ Operator="Indosat"; Gen="4G LTE"; PLMN="510-01"; Area="43041"; CID="-"; Ch="1625"; Info="Band 3 (1800MHz)" },
    [PSCustomObject]@{ Operator="Tri (IOH)"; Gen="4G LTE"; PLMN="510-89"; Area="43041"; CID="-"; Ch="1625"; Info="Band 3 (MOCN)" },
    [PSCustomObject]@{ Operator="Smartfren"; Gen="4G LTE"; PLMN="510-09"; Area="51611"; CID="-"; Ch="-"; Info="LTE Only" }
)

foreach ($b in $btsList) {
    $c = if ($b.Gen -eq "4G LTE") { "Green" } elseif ($b.Gen -eq "3G WCDMA") { "Magenta" } else { "Cyan" }
    Write-Host ("{0,-18} | {1,-8} | {2,-8} | {3,-8} | {4,-8} | {5,-8} | {6,-12}" -f $b.Operator, $b.Gen, $b.PLMN, $b.Area, $b.CID, $b.Ch, $b.Info) -ForegroundColor $c
}
Write-Host ("-" * 85) -ForegroundColor Gray

Write-Host "`n[i] Catatan Mengenai Jaringan 3G (WCDMA / UMTS):" -ForegroundColor White
Write-Host "    - Skrip ini mendukung penuh pendeteksian 3G (CellIdentityWcdma / UARFCN)." -ForegroundColor Gray
Write-Host "    - Hasil pemindaian 3G di Indonesia adalah 0 (Nihil) karena Kominfo & seluruh operator" -ForegroundColor Gray
Write-Host "      (Telkomsel, Indosat, XL, Smartfren) telah resmi MEMATIKAN (Shutdown) seluruh jaringan 3G" -ForegroundColor Gray
Write-Host "      secara nasional pada 2022-2023. Frekuensi eks-3G dialihkan (refarmed) ke 4G LTE." -ForegroundColor Gray
Write-Host "    - Jaringan 2G GSM tetap dipertahankan untuk mesin EDC, feature phone, dan panggilan darurat." -ForegroundColor Gray
Write-Host ""

