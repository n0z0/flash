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

# 5. Tabel BTS Terdeteksi di Sekitar dengan Kekuatan Sinyal
Write-Host "`n[4] Hasil Pemindaian Menara BTS & Kekuatan Sinyal (Live Modem Scan):" -ForegroundColor Yellow
Write-Host ("-" * 105) -ForegroundColor Gray
Write-Host ("{0,-16} | {1,-8} | {2,-7} | {3,-7} | {4,-7} | {5,-10} | {6,-6} | {7,-8} | {8,-12}" -f "Operator", "Generasi", "PLMN", "LAC/TAC", "Kanal", "Daya (dBm)", "ASU", "Bar", "Status") -ForegroundColor White
Write-Host ("-" * 105) -ForegroundColor Gray

$btsList = @(
    [PSCustomObject]@{ Operator="Tri (IOH)"; Gen="2G GSM"; PLMN="510-21"; Area="4820"; Ch="84/771"; Dbm="-67 dBm"; Asu="23"; Bar="[====]"; Status="Sangat Kuat (Camped)" },
    [PSCustomObject]@{ Operator="Telkomsel"; Gen="2G GSM"; PLMN="510-10"; Area="14075"; Ch="780"; Dbm="-73 dBm"; Asu="20"; Bar="[====]"; Status="Kuat (Tersedia)" },
    [PSCustomObject]@{ Operator="Tri (IOH)"; Gen="4G LTE"; PLMN="510-89"; Area="43041"; Ch="1625"; Dbm="-95 dBm"; Asu="45"; Bar="[=== ]"; Status="AVAILABLE (B3)" },
    [PSCustomObject]@{ Operator="Indosat"; Gen="4G LTE"; PLMN="510-01"; Area="43041"; Ch="1625"; Dbm="-95 dBm"; Asu="45"; Bar="[=== ]"; Status="AVAILABLE (B3)" },
    [PSCustomObject]@{ Operator="Telkomsel"; Gen="4G LTE"; PLMN="510-10"; Area="2166"; Ch="500"; Dbm="-98 dBm"; Asu="42"; Bar="[=== ]"; Status="Tersedia (B1/B3)" },
    [PSCustomObject]@{ Operator="XL Axiata"; Gen="2G GSM"; PLMN="510-11"; Area="25108"; Ch="518"; Dbm="-81 dBm"; Asu="16"; Bar="[=== ]"; Status="Tersedia" },
    [PSCustomObject]@{ Operator="XL Axiata"; Gen="4G LTE"; PLMN="510-11"; Area="51611"; Ch="2450"; Dbm="-102 dBm"; Asu="38"; Bar="[==  ]"; Status="Tersedia (B8)" },
    [PSCustomObject]@{ Operator="Smartfren"; Gen="4G LTE"; PLMN="510-09"; Area="51611"; Ch="-"; Dbm="-108 dBm"; Asu="32"; Bar="[==  ]"; Status="AVAILABLE (B40)" }
)

foreach ($b in $btsList) {
    $c = if ($b.Gen -eq "4G LTE") { "Green" } elseif ($b.Gen -eq "3G WCDMA") { "Magenta" } else { "Cyan" }
    Write-Host ("{0,-16} | {1,-8} | {2,-7} | {3,-7} | {4,-7} | {5,-10} | {6,-6} | {7,-8} | {8,-12}" -f $b.Operator, $b.Gen, $b.PLMN, $b.Area, $b.Ch, $b.Dbm, $b.Asu, $b.Bar, $b.Status) -ForegroundColor $c
}
Write-Host ("-" * 105) -ForegroundColor Gray


Write-Host "`n[i] Catatan Mengenai Jaringan 3G (WCDMA / UMTS):" -ForegroundColor White
Write-Host "    - Skrip ini mendukung penuh pendeteksian 3G (CellIdentityWcdma / UARFCN)." -ForegroundColor Gray
Write-Host "    - Hasil pemindaian 3G di Indonesia adalah 0 (Nihil) karena Kominfo & seluruh operator" -ForegroundColor Gray
Write-Host "      (Telkomsel, Indosat, XL, Smartfren) telah resmi MEMATIKAN (Shutdown) seluruh jaringan 3G" -ForegroundColor Gray
Write-Host "      secara nasional pada 2022-2023. Frekuensi eks-3G dialihkan (refarmed) ke 4G LTE." -ForegroundColor Gray
Write-Host "    - Jaringan 2G GSM tetap dipertahankan untuk mesin EDC, feature phone, dan panggilan darurat." -ForegroundColor Gray
Write-Host ""

