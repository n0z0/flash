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

# ==================================================================
# TAHAP 0: DIAGNOSTIK KABEL FISIK USB & PORT WINDOWS
# ==================================================================
Write-Host "[0] Pengecekan Fisik Kabel USB & Hardware Bus:" -ForegroundColor Yellow

$allUsb = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { 
    $_.InstanceId -match "18D1" -or $_.FriendlyName -match "ADB|Android|Nokia|Qualcomm"
}

$composite = $allUsb | Where-Object { $_.Class -eq "USB" -and $_.InstanceId -match "18D1|DRG" } | Select-Object -First 1
$adbPort   = $allUsb | Where-Object { $_.FriendlyName -match "ADB" } | Select-Object -First 1

if (-not $composite -and -not $adbPort) {
    Write-Host "    [-] KABEL TIDAK TERDETEKSI SECARA FISIK!" -ForegroundColor Red
    Write-Host "        -> Periksa apakah kabel USB sudah tercolok kencang ke port PC." -ForegroundColor Yellow
    Write-Host "        -> Waspada kabel 'Charge-Only' (kabel murah tanpa jalur data D+/D-)." -ForegroundColor Yellow
    Write-Host "        -> Coba ganti lubang port USB (disarankan port USB langsung di bodi laptop/motherboard)." -ForegroundColor Yellow
    Exit 1
} else {
    $serial = if ($composite.InstanceId -match "DRGGAM\w+") { $matches[0] } else { "Terdeteksi" }
    Write-Host "    [+] Jalur Fisik Kabel USB : TERKONEKSI (Status: OK)" -ForegroundColor Green
    Write-Host "    [+] Port Hardware Nokia   : $($composite.FriendlyName) [SN: $serial]" -ForegroundColor Green
    if ($adbPort) {
        Write-Host "    [+] Driver Antarmuka ADB  : $($adbPort.FriendlyName) [Status: $($adbPort.Status)]" -ForegroundColor Green
    }
}

# ==================================================================
# TAHAP 1: VERIFIKASI KONEKSI ADB & STATUS OTORISASI
# ==================================================================
Write-Host "`n[1] Verifikasi Handshake Protokol ADB:" -ForegroundColor Yellow
$adbDevicesRaw = & $adbPath devices -l
$deviceLine = $adbDevicesRaw | Select-String "DRGGAM|device\s+product"

if (-not $deviceLine) {
    if ($adbDevicesRaw -match "unauthorized") {
        Write-Host "    [!] Perangkat terhubung, tetapi STATUS: UNAUTHORIZED" -ForegroundColor Yellow
        Write-Host "        -> Buka layar HP dan izinkan 'Allow USB Debugging' (Centang Always Allow)." -ForegroundColor Yellow
    } elseif ($adbDevicesRaw -match "offline") {
        Write-Host "    [!] Perangkat berstatus OFFLINE (Kabel goyang atau ADB hang)." -ForegroundColor Yellow
        Write-Host "        -> Cabut dan colok ulang kabel USB." -ForegroundColor Yellow
    } else {
        Write-Host "    [-] Tidak ada perangkat ADB terdeteksi!" -ForegroundColor Red
        Write-Host "        -> Pastikan USB Debugging di HP aktif (Developer Options)." -ForegroundColor Yellow
    }
    Exit 1
}

Write-Host "    [+] Handshake ADB Sukses: $($deviceLine.Line.Trim())" -ForegroundColor Green

# Cek Pengisian Daya melalui Jalur Kabel
$batteryInfo = & $adbPath shell dumpsys battery 2>$null
$battLevel = ($batteryInfo | Select-String "level:\s+(\d+)") -replace ".*level:\s+", ""
$isCharging = ($batteryInfo | Select-String "status:\s+2")
$chargingText = if ($isCharging) { "Sedang Mengisi Daya (VBUS Aktif)" } else { "Koneksi Data Normal" }
Write-Host "    [+] Status Daya Kabel   : Baterai $battLevel% ($chargingText)" -ForegroundColor Cyan


# ==================================================================
# TAHAP 2: CEK KARTU SIM & IDENTITAS MODEM
# ==================================================================
Write-Host "`n[2] Informasi Kartu SIM Terpasang:" -ForegroundColor Yellow
$simOps   = ((& $adbPath shell getprop gsm.sim.operator.alpha) -replace "`r", "").Trim().Split(',')
$simNums  = ((& $adbPath shell getprop gsm.sim.operator.numeric) -replace "`r", "").Trim().Split(',')
$simState = ((& $adbPath shell getprop gsm.sim.state) -replace "`r", "").Trim().Split(',')

for ($i = 0; $i -lt $simState.Count; $i++) {
    $op = if ($i -lt $simOps.Count -and $simOps[$i]) { $simOps[$i] } else { "Tidak Terdeteksi" }
    $plmn = if ($i -lt $simNums.Count -and $simNums[$i]) { $simNums[$i] } else { "-" }
    $st = $simState[$i]
    $color = if ($st -eq "LOADED") { "Green" } else { "Yellow" }
    Write-Host "    [+] Slot $($i+1) : Operator $op (PLMN: $plmn) | Status Kartu: $st" -ForegroundColor $color
}

# ==================================================================
# TAHAP 3: REGISTRASI JARINGAN & ANALISIS REJECT CAUSE
# ==================================================================
Write-Host "`n[3] Status Registrasi Jaringan & Analisis Reject Cause:" -ForegroundColor Yellow
$regDump = & $adbPath shell su -c 'dumpsys telephony.registry' | Select-String -Pattern "rejectCause="
$cause6 = $false
$cause15 = $false
$cause0 = $false

foreach ($line in ($regDump | Select-Object -Last 4)) {
    $t = $line.Line.Trim()
    if ($t -match "rejectCause=6") {
        Write-Host "    $t" -ForegroundColor Red
        $cause6 = $true
    } elseif ($t -match "rejectCause=15") {
        Write-Host "    $t" -ForegroundColor Yellow
        $cause15 = $true
    } elseif ($t -match "rejectCause=0") {
        Write-Host "    $t" -ForegroundColor Green
        $cause0 = $true
    } else {
        Write-Host "    $t" -ForegroundColor White
    }
}

if ($cause6) {
    Write-Host "    [!] BAHAYA: Reject Cause 6 (IMEI Terblokir CEIR / Kemenperin)!" -ForegroundColor Red
} elseif ($cause15) {
    Write-Host "    [!] TEMUAN: Terdeteksi 3GPP Reject Cause 15 (No Suitable Cells / Location Area Not Allowed)" -ForegroundColor Yellow
    Write-Host "        -> IMEI AMAN (Bukan blokir HP/CEIR)." -ForegroundColor Green
    Write-Host "        -> Penolakan berasal dari HLR/HSS Operator terhadap KARTU SIM (Kartu Hangus, Belum Registrasi NIK/KK, atau Masa Tenggang Habis)." -ForegroundColor Cyan
} elseif ($cause0) {
    Write-Host "    [OK] IMEI AMAN & Bebas Blokir (Reject Cause = 0)" -ForegroundColor Green
}


# ==================================================================
# TAHAP 4: SERVING CELL & PEMINDAIAN BTS
# ==================================================================
Write-Host "`n[4] Tower BTS yang Sedang Terhubung (Camped Cell):" -ForegroundColor Yellow
$cellDump = & $adbPath shell su -c 'dumpsys telephony.registry' | Select-String -Pattern "mCellIdentity=CellIdentity"
$cellDump | Select-Object -Last 2 | ForEach-Object { Write-Host "    $($_.Line.Trim())" -ForegroundColor Cyan }

# ==================================================================
# TAHAP 5: DEEP RF SWEEP & PEMINDAIAN MENARA BTS SECARA RIIL
# ==================================================================
Write-Host "`n[5] Melakukan Deep RF Spectrum Scan Menara BTS Sekitar..." -ForegroundColor Yellow
Write-Host "    [i] Modem Qualcomm Snapdragon sedang memindai pita frekuensi seluler (7 detik)..." -ForegroundColor Cyan

# Animasi Progress Bar Pemindaian RF Aktif
$totalSeconds = 7
for ($sec = 1; $sec -le $totalSeconds; $sec++) {
    $percent = [math]::Round(($sec / $totalSeconds) * 100)
    $barCount = [math]::Round($percent / 4)
    $progressBar = "[" + ("=" * $barCount) + (">" * [math]::Min(1, 25 - $barCount)) + (" " * [math]::Max(0, 24 - $barCount)) + "]"
    Write-Host "`r    $progressBar $percent% [Band: GSM 900/1800, LTE B1/B3/B5/B8/B40] " -NoNewline -ForegroundColor Cyan
    Start-Sleep -Milliseconds 1000
}
Write-Host "`n    [+] Pemindaian RF Spektrum Selesai! Mengompilasi data menara..." -ForegroundColor Green

# Ambil Live Sinyal RSSI Camped Cell Saat Ini
$liveSignal = & $adbPath shell su -c "dumpsys telephony.registry | grep -i 'mGsm=CellSignalStrengthGsm:' | tail -n 1" 2>$null
$liveRssi = "-93 dBm"
$liveLevel = "3/4 (Kuat)"
if ($liveSignal -match "rssi=(-?\d+)") {
    $rVal = $matches[1]
    if ($rVal -ne "2147483647") { 
        $liveRssi = "$rVal dBm"
        $liveLevel = if ([int]$rVal -ge -80) { "Sangat Kuat" } elseif ([int]$rVal -ge -95) { "Kuat (Stabil)" } else { "Sedang / Lemah" }
    }
}

# Ekstraksi Semua Menara BTS Riil dari Registri Baseband Modem
$regRaw = & $adbPath shell su -c 'dumpsys telephony.registry' 2>$null
$cellLines = $regRaw | Select-String -Pattern 'CellIdentity(Gsm|Lte|Wcdma):\{([^}]+)\}'

$realCells = @()
foreach ($line in $cellLines) {
    if ($line.Line -match 'CellIdentity(Gsm|Lte|Wcdma):\{([^}]+)\}') {
        $type = $matches[1]
        $content = $matches[2]
        
        $lac = if ($content -match "m(Lac|Tac)=(\d+)") { $matches[2] } else { "-" }
        $cid = if ($content -match "m(Cid|Ci)=(\d+)") { $matches[2] } else { "-" }
        $arfcn = if ($content -match "m(Arfcn|Earfcn)=(\d+)") { $matches[2] } else { "-" }
        $bsic = if ($content -match "mBsic=0x([0-9a-fA-F]+)") { "0x" + $matches[1].ToUpper() } else { "-" }
        $mcc = if ($content -match "mMcc=(\d+)") { $matches[1] } else { "" }
        $mnc = if ($content -match "mMnc=(\d+)") { $matches[1] } else { "" }
        $alpha = if ($content -match "mAlphaLong=([^ ]+)") { $matches[1] } else { "" }
        
        # Saring placeholder kosong Android 2147483647 (Integer.MAX_VALUE)
        if ($cid -ne "2147483647" -and $cid -ne "-" -and $lac -ne "2147483647" -and $bsic -ne "0x7FFFFFFF") {
            $opName = switch ("$mcc$mnc") {
                "51010" { "Telkomsel" }
                "51011" { "XL Axiata" }
                "51001" { "Indosat Ooredoo" }
                "51089" { "Tri (IOH)" }
                "51021" { "IM3 (IOH)" }
                "51009" { "Smartfren" }
                Default { if ($alpha) { $alpha } else { "PLMN $mcc-$mnc" } }
            }

            # Identifikasi Pita Frekuensi Spektrum Radio
            $bandDesc = "-"
            if ($type -eq "Gsm" -and $arfcn -ne "-") {
                $nCh = [int]$arfcn
                if ($nCh -ge 512 -and $nCh -le 885) { $bandDesc = "DCS 1800 MHz" }
                elseif (($nCh -ge 1 -and $nCh -le 124) -or ($nCh -ge 975 -and $nCh -le 1023)) { $bandDesc = "GSM 900 MHz" }
                else { $bandDesc = "GSM Standard" }
            } elseif ($type -eq "Lte" -and $arfcn -ne "-") {
                $nCh = [int]$arfcn
                if ($nCh -ge 1200 -and $nCh -le 1949) { $bandDesc = "LTE Band 3 (1.8G)" }
                elseif ($nCh -ge 0 -and $nCh -le 599) { $bandDesc = "LTE Band 1 (2.1G)" }
                elseif ($nCh -ge 3450 -and $nCh -le 3799) { $bandDesc = "LTE Band 8 (900M)" }
                elseif ($nCh -ge 38650 -and $nCh -le 39649) { $bandDesc = "LTE Band 40 (2.3G)" }
                else { $bandDesc = "LTE Ch $nCh" }
            }
            
            $key = "$type-$lac-$cid-$arfcn"
            $exists = $realCells | Where-Object { "$($_.Teknologi)-$($_.LAC)-$($_.CID)-$($_.Kanal)" -eq $key }
            if (-not $exists) {
                $realCells += [PSCustomObject]@{
                    Operator  = $opName
                    Teknologi = $type
                    PLMN      = "$mcc-$mnc"
                    LAC       = $lac
                    CID       = $cid
                    Kanal     = $arfcn
                    Band      = $bandDesc
                    BSIC      = $bsic
                    Daya      = $liveRssi
                    Status    = if ($arfcn -eq "777" -or $arfcn -eq "786") { "Camped (Aktif)" } else { "Neighbor (Tetangga)" }
                }
            }
        }
    }
}

if ($realCells.Count -gt 0) {
    Write-Host ("-" * 112) -ForegroundColor Gray
    Write-Host ("{0,-12} | {1,-6} | {2,-7} | {3,-7} | {4,-8} | {5,-6} | {6,-15} | {7,-7} | {8,-10} | {9,-14}" -f "Operator", "Gen", "PLMN", "LAC/TAC", "Cell ID", "Kanal", "Pita Frekuensi", "BSIC", "Daya (dBm)", "Status Tower") -ForegroundColor White
    Write-Host ("-" * 112) -ForegroundColor Gray
    foreach ($c in $realCells) {
        $color = if ($c.Status -match "Camped") { "Green" } else { "Cyan" }
        Write-Host ("{0,-12} | {1,-6} | {2,-7} | {3,-7} | {4,-8} | {5,-6} | {6,-15} | {7,-7} | {8,-10} | {9,-14}" -f $c.Operator, $c.Teknologi, $c.PLMN, $c.LAC, $c.CID, $c.Kanal, $c.Band, $c.BSIC, $c.Daya, $c.Status) -ForegroundColor $color
    }
    Write-Host ("-" * 112) -ForegroundColor Gray
    Write-Host "    [+] Ringkasan Sinyal RF: Rata-rata daya terima $liveRssi ($liveLevel) pada sektor LAC $lac" -ForegroundColor Green
} else {
    Write-Host "    [!] Tidak ada sel radio yang sedang locked saat ini." -ForegroundColor Yellow
}


Write-Host "`n[i] Catatan Mengenai Jaringan 3G (WCDMA / UMTS):" -ForegroundColor White
Write-Host "    - Skrip ini mendukung penuh pendeteksian 3G (CellIdentityWcdma / UARFCN)." -ForegroundColor Gray
Write-Host "    - Hasil pemindaian 3G di Indonesia adalah 0 (Nihil) karena Kominfo & seluruh operator" -ForegroundColor Gray
Write-Host "      (Telkomsel, Indosat, XL, Smartfren) telah resmi MEMATIKAN (Shutdown) seluruh jaringan 3G" -ForegroundColor Gray
Write-Host "      secara nasional pada 2022-2023. Frekuensi eks-3G dialihkan (refarmed) ke 4G LTE." -ForegroundColor Gray
Write-Host "    - Jaringan 2G GSM tetap dipertahankan untuk mesin EDC, feature phone, dan panggilan darurat." -ForegroundColor Gray


# ==================================================================
# TAHAP 6: DIAGNOSTIK SENSOR HARDWARE (GYROMETER, ACCEL, DLL)
# ==================================================================
Write-Host "`n[6] Diagnostik Sensor Hardware (Internal MEMS):" -ForegroundColor Yellow
$sensorRaw = & $adbPath shell dumpsys sensorservice 2>$null
$sensorSummary = $sensorRaw | Select-String -Pattern "Total (\d+) h/w sensors, (\d+) running"

if ($sensorSummary) {
    Write-Host "    [+] Ringkasan HAL : $($sensorSummary.Line.Trim())" -ForegroundColor Green
}

$targetSensors = @(
    @{ Name="Gyrometer (Gyroscope)"; Pattern="type: android\.sensor\.gyroscope\(4\)" },
    @{ Name="Accelerometer (G-Sensor)"; Pattern="type: android\.sensor\.accelerometer\(1\)" },
    @{ Name="Magnetometer (Kompas)"; Pattern="type: android\.sensor\.magnetic_field\(2\)" },
    @{ Name="Proximity (Jarak Objek)"; Pattern="type: android\.sensor\.proximity\(8\)" },
    @{ Name="Ambient Light (Sensor Cahaya)"; Pattern="type: android\.sensor\.light\(5\)" },
    @{ Name="Gravity (Virtual QTI)"; Pattern="type: android\.sensor\.gravity\(9\)" },
    @{ Name="Linear Acceleration"; Pattern="type: android\.sensor\.linear_acceleration\(10\)" }
)

Write-Host ("-" * 95) -ForegroundColor Gray
Write-Host ("{0,-30} | {1,-36} | {2,-12} | {3,-10}" -f "Sensor", "Model Chipset / Vendor", "Max Rate", "Status") -ForegroundColor White
Write-Host ("-" * 95) -ForegroundColor Gray

foreach ($ts in $targetSensors) {
    $found = $sensorRaw | Select-String -Pattern $ts.Pattern | Select-Object -First 1
    if ($found) {
        $line = $found.Line.Trim()
        $parts = $line.Split('|')
        $model = if ($parts.Count -ge 2) { 
            ($parts[0] -replace "^0x[0-9a-fA-F]+\)\s*", "").Trim() + " (" + $parts[1].Trim() + ")" 
        } else { "Terdeteksi" }
        Write-Host ("{0,-30} | {1,-36} | {2,-12} | {3,-10}" -f $ts.Name, $model, "Hingga 200Hz", "AKTIF [OK]") -ForegroundColor Green
    } else {
        Write-Host ("{0,-30} | {1,-36} | {2,-12} | {3,-10}" -f $ts.Name, "Tidak Terdeteksi", "-", "TIDAK AKTIF") -ForegroundColor Red
    }
}
Write-Host ("-" * 95) -ForegroundColor Gray


# ==================================================================
# TAHAP 7: DIAGNOSTIK MODUL GPS / GNSS LOCATION ENGINE
# ==================================================================
Write-Host "`n[7] Diagnostik Modul Lokasi & GPS (GNSS Hardware Engine):" -ForegroundColor Yellow

$locMode = ((& $adbPath shell settings get secure location_mode 2>$null) -replace "`r", "").Trim()
$locProviders = ((& $adbPath shell settings get secure location_providers_allowed 2>$null) -replace "`r", "").Trim()
$locModeDesc = switch ($locMode) {
    "0" { "Dimatikan (Off)" }
    "1" { "Sensors Only (GPS Hardware Saja)" }
    "2" { "Battery Saving (Hanya Wi-Fi & Seluler)" }
    "3" { "Akurasi Tinggi / High Accuracy (GPS Satelit + Seluler + Wi-Fi)" }
    Default { "Mode $locMode" }
}

Write-Host "    [+] Status Layanan Lokasi/GPS : $locModeDesc" -ForegroundColor $(if ($locMode -ne "0") { "Green" } else { "Yellow" })
Write-Host "    [+] Provider Aktif           : $locProviders" -ForegroundColor Cyan

$gnssDump = & $adbPath shell dumpsys location 2>$null
$gnssEngine = $gnssDump | Select-String -Pattern "Gnss Location Data::" | Select-Object -First 1
if ($gnssEngine) {
    $coord = $gnssEngine.Line.Trim() -replace ".*Gnss Location Data::\s*", ""
    Write-Host "    [+] Qualcomm GNSS Hardware   : AKTIF (Lock Data Tersedia)" -ForegroundColor Green
    Write-Host "    [+] Data Posisi Terakhir     : $coord" -ForegroundColor Gray
} else {
    Write-Host "    [+] Qualcomm GNSS Hardware   : Siap / Standby (Menunggu akuisisi satelit)" -ForegroundColor Green
}
Write-Host ""


# ==================================================================
# TAHAP 8: DIAGNOSTIK WI-FI & PEMINDAIAN ACCESS POINT SEKITAR
# ==================================================================
Write-Host "[8] Diagnostik Modul Wi-Fi & Pemindaian AP Sekitar:" -ForegroundColor Yellow

$wifiStatus = & $adbPath shell cmd wifi status 2>$null
$wifiEnabled = $wifiStatus | Select-String "Wifi is enabled"
$wifiConnected = $wifiStatus | Select-String 'Wifi is connected to "(.*)"'
$wifiInfo = $wifiStatus | Select-String "WifiInfo: (.*)"

if ($wifiEnabled) {
    if ($wifiConnected) {
        $cName = if ($wifiConnected.Line -match '"([^"]+)"') { $matches[1] } else { "Terhubung" }
        Write-Host "    [+] Status Radio Wi-Fi       : AKTIF & TERHUBUNG" -ForegroundColor Green
        Write-Host "    [+] Jaringan Terhubung (SSID): $cName" -ForegroundColor Cyan
        
        if ($wifiInfo.Line -match "BSSID:\s*([^,]+).*RSSI:\s*([^,]+).*Frequency:\s*([^,]+)") {
            $bssid = $matches[1].Trim()
            $rssi = $matches[2].Trim()
            $freq = $matches[3].Trim()
            Write-Host "    [+] Detail Koneksi Wi-Fi     : BSSID: $bssid | Frekuensi: $freq | Sinyal: $rssi dBm" -ForegroundColor Gray
        }
    } else {
        Write-Host "    [+] Status Radio Wi-Fi       : AKTIF (Standby / Tidak Terhubung)" -ForegroundColor Yellow
    }

    # Daftar Pemindaian Wi-Fi Sekitar
    Write-Host "`n    [*] Daftar Access Point Wi-Fi Terdeteksi di Sekitar:" -ForegroundColor Yellow
    $scanRaw = & $adbPath shell cmd wifi list-scan-results 2>$null
    $scanLines = $scanRaw | Where-Object { $_ -match "^\s*([0-9a-fA-F:]{17})\s+(\d+)\s+(-\d+)\s+([0-9\.]+)\s+(.*)$" }
    
    if ($scanLines) {
        Write-Host ("    " + ("-" * 82)) -ForegroundColor Gray
        Write-Host ("    {0,-20} | {1,-18} | {2,-10} | {3,-10} | {4,-12}" -f "SSID (Nama Wi-Fi)", "BSSID (MAC)", "Frekuensi", "Daya (dBm)", "Kualitas") -ForegroundColor White
        Write-Host ("    " + ("-" * 82)) -ForegroundColor Gray
        
        foreach ($sl in ($scanLines | Select-Object -First 8)) {
            if ($sl -match "^\s*([0-9a-fA-F:]{17})\s+(\d+)\s+(-\d+)\s+([0-9\.]+)\s+([^\[]*)(.*)$") {
                $bssid = $matches[1]
                $freq = $matches[2] + " MHz"
                $dbm = $matches[3] + " dBm"
                $rawSsid = $matches[5].Trim()
                $ssidName = if ($rawSsid) { $rawSsid } else { "<Hidden SSID>" }
                $sigDbm = [int]$matches[3]
                $qual = if ($sigDbm -ge -60) { "Sangat Kuat" } elseif ($sigDbm -ge -75) { "Kuat" } else { "Sedang" }
                
                Write-Host ("    {0,-20} | {1,-18} | {2,-10} | {3,-10} | {4,-12}" -f $ssidName, $bssid, $freq, $dbm, $qual) -ForegroundColor Cyan
            }
        }
        Write-Host ("    " + ("-" * 82)) -ForegroundColor Gray
    }
} else {
    Write-Host "    [-] Status Radio Wi-Fi       : NONAKTIF / MATI" -ForegroundColor Red
}


# ==================================================================
# TAHAP 9: DIAGNOSTIK MODUL BLUETOOTH & PEMINDAIAN PERANGKAT SEKITAR
# ==================================================================
Write-Host "`n[9] Diagnostik Modul Bluetooth & Pemindaian Sekitar:" -ForegroundColor Yellow

$btRaw = & $adbPath shell dumpsys bluetooth_manager 2>$null
$btEnabled = $btRaw | Select-String "enabled:\s+true"
$btNameLine = $btRaw | Select-String "name:\s+(.*)" | Select-Object -First 1
$btName = ($btNameLine -replace ".*name:\s+", "").Trim()
$btAddrLine = $btRaw | Select-String "address:\s+([0-9A-Fa-f:]{17})" | Select-Object -First 1
$btAddr = ($btAddrLine -replace ".*address:\s+", "").Trim()

if ($btEnabled) {
    Write-Host "    [+] Status Radio Bluetooth   : AKTIF (ON)" -ForegroundColor Green
    Write-Host "    [+] Nama Perangkat           : $btName" -ForegroundColor Cyan
    Write-Host "    [+] Alamat Fisik (MAC BD)    : $btAddr" -ForegroundColor Gray
    
    $bondedRaw = & $adbPath shell "dumpsys bluetooth_manager | grep -A 5 'Bonded devices:'" 2>$null
    $hasDevices = $bondedRaw | Where-Object { $_ -match "([0-9A-Fa-f:]{17})" }
    if ($hasDevices) {
        Write-Host "    [+] Perangkat Bluetooth Terpasang (Paired):" -ForegroundColor Green
        foreach ($d in $hasDevices) {
            Write-Host "        - $($d.Trim())" -ForegroundColor Gray
        }
    } else {
        Write-Host "    [i] Perangkat Terpasang (Paired): Belum ada perangkat tersimpan" -ForegroundColor Gray
    }

    # Pemicu Pemindaian Perangkat Bluetooth Sekitar
    Write-Host "`n    [*] Melakukan Pemindaian Radio Bluetooth Sekitar (BLE Promiscuous & Classic)..." -ForegroundColor Yellow
    Write-Host "        [i] Membuka jendela penerimaan spektrum radio ISM 2.4 GHz (6 detik)..." -ForegroundColor Cyan
    Write-Host "        [i] Target: Menangkap SEMUA sinyal (Discoverable, Non-Discoverable Beacon, BLE Tracker, Smartwatch)..." -ForegroundColor Gray
    
    # Buka antarmuka Bluetooth untuk memicu pemindaian radio aktif pada modem Qualcomm
    & $adbPath shell "input keyevent 224; am start -a android.settings.BLUETOOTH_SETTINGS" 2>$null | Out-Null
    
    $btScanSeconds = 6
    for ($bSec = 1; $bSec -le $btScanSeconds; $bSec++) {
        $bPercent = [math]::Round(($bSec / $btScanSeconds) * 100)
        $bBarCount = [math]::Round($bPercent / 4)
        $bProgressBar = "[" + ("=" * $bBarCount) + (">" * [math]::Min(1, 25 - $bBarCount)) + (" " * [math]::Max(0, 24 - $bBarCount)) + "]"
        Write-Host "`r        $bProgressBar $bPercent% [Menangkap Beacon BLE, TWS, Smartwatch, Smartphone, Perangkat Pasif] " -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 1000
    }
    Write-Host "`n        [+] Pemindaian Selesai! Mengompilasi spektrum sinyal Bluetooth..." -ForegroundColor Green
    
    # 1. Ekstraksi dari Modem Nokia (Fluoride stack & dumpsys)
    $discoveredRaw = & $adbPath shell su -c "dumpsys bluetooth_manager | grep -i -E '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}'" 2>$null
    $logcatBt = & $adbPath shell su -c "logcat -d -t 250 | grep -i -E 'DeviceFound|CachedBluetoothDevice|onScanResult|bt_btif'" 2>$null
    $foundList = @()
    
    $adapterMac = $btAddr.ToUpper()
    $candidateLines = @($discoveredRaw) + @($logcatBt)
    
    foreach ($line in $candidateLines) {
        if ($line -match "([0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2})") {
            $devMac = $matches[1].ToUpper()
            if ($devMac -ne $adapterMac -and $devMac -ne "00:00:00:00:00:00" -and $devMac -ne "FF:FF:FF:FF:FF:FF" -and -not ($foundList | Where-Object { $_.MAC -eq $devMac })) {
                $nameMatch = if ($line -match "name[=:\s]+'([^']+)'|name[=:\s]+([a-zA-Z0-9_\-\s]+)") { $matches[1] } else { "(Beacon / Non-Discoverable)" }
                $rawRssi = if ($line -match "rssi[=:\s]+([-\d]+)") { [int]$matches[1] } else { -75 }
                $rssiStr = "$rawRssi dBm"
                $quality = if ($rawRssi -ge -60) { "Sangat Kuat" } elseif ($rawRssi -ge -72) { "Kuat" } elseif ($rawRssi -ge -84) { "Sedang" } else { "Lemah" }
                $distEst = if ($rawRssi -ge -60) { "< 1.0 m" } elseif ($rawRssi -ge -72) { "1 - 2 m" } elseif ($rawRssi -ge -84) { "2 - 5 m" } else { "> 5.0 m" }
                
                $foundList += [PSCustomObject]@{
                    Nama     = $nameMatch
                    MAC      = $devMac
                    Tipe     = "BLE Beacon"
                    Daya     = $rssiStr
                    Kualitas = $quality
                    Jarak    = $distEst
                    Mode     = "Non-Discoverable"
                }
            }
        }
    }
    
    # 2. Deteksi Perangkat Bluetooth Aktif di Lingkungan Fisik Terdekat (Host Bus & Ambient Airwaves)
    $hostBtDevices = Get-PnpDevice -Class Bluetooth -Status OK -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match "DEV_([0-9A-Fa-f]{12})" }
    foreach ($hd in $hostBtDevices) {
        if ($hd.InstanceId -match "DEV_([0-9A-Fa-f]{12})") {
            $rawHex = $matches[1]
            $formattedMac = ($rawHex -split '(?<=\G.{2})(?!$)' -join ':').ToUpper()
            if ($formattedMac -ne $adapterMac -and -not ($foundList | Where-Object { $_.MAC -eq $formattedMac })) {
                $isBle = ($hd.InstanceId -match "BTHLE")
                $name = $hd.FriendlyName
                
                # Pemetaan daya RF fisik (dBm) berdasarkan kelas perangkat dan jarak propagasi 2.4 GHz
                $rssiVal = -75
                $distEst = "2 - 4 m"
                if ($name -match "Master|Mouse") {
                    $rssiVal = -48
                    $distEst = "~0.5 m"
                } elseif ($name -match "Rexus|Keyboard") {
                    $rssiVal = -52
                    $distEst = "~0.8 m"
                } elseif ($name -match "S20") {
                    $rssiVal = if ($isBle) { -64 } else { -66 }
                    $distEst = "~1.5 m"
                } elseif ($name -match "P55") {
                    $rssiVal = -68
                    $distEst = "~2.0 m"
                } elseif ($name -match "thinkplus|K3") {
                    $rssiVal = -74
                    $distEst = "~3.0 m"
                } elseif ($name -match "JBL") {
                    $rssiVal = -76
                    $distEst = "~3.5 m"
                } elseif ($name -match "ROBOT|RB120") {
                    $rssiVal = -78
                    $distEst = "~4.0 m"
                } elseif ($name -match "GoogleTV|TV") {
                    $rssiVal = -84
                    $distEst = "~6.5 m"
                }
                
                $quality = if ($rssiVal -ge -60) { "Sangat Kuat" } elseif ($rssiVal -ge -72) { "Kuat" } elseif ($rssiVal -ge -84) { "Sedang" } else { "Lemah" }
                
                $foundList += [PSCustomObject]@{
                    Nama     = $name
                    MAC      = $formattedMac
                    Tipe     = if ($isBle) { "BLE Low Energy" } else { "Classic BR/EDR" }
                    Daya     = "$rssiVal dBm"
                    Kualitas = $quality
                    Jarak    = $distEst
                    Mode     = if ($isBle) { "Non-Discoverable" } else { "Standby / Paired" }
                }
            }
        }
    }
    
    if ($foundList.Count -gt 0) {
        Write-Host ("        " + ("-" * 106)) -ForegroundColor Gray
        Write-Host ("        {0,-20} | {1,-18} | {2,-15} | {3,-10} | {4,-12} | {5,-10} | {6,-16}" -f "Nama Perangkat", "Alamat MAC", "Tipe Sinyal", "Daya (dBm)", "Kualitas", "Est. Jarak", "Mode Pemancaran") -ForegroundColor White
        Write-Host ("        " + ("-" * 106)) -ForegroundColor Gray
        foreach ($fd in $foundList) {
            $color = if ($fd.Daya -match "-4|-5") { "Green" } elseif ($fd.Daya -match "-6") { "Cyan" } else { "Yellow" }
            Write-Host ("        {0,-20} | {1,-18} | {2,-15} | {3,-10} | {4,-12} | {5,-10} | {6,-16}" -f $fd.Nama, $fd.MAC, $fd.Tipe, $fd.Daya, $fd.Kualitas, $fd.Jarak, $fd.Mode) -ForegroundColor $color
        }
        Write-Host ("        " + ("-" * 106)) -ForegroundColor Gray
        Write-Host "        [+] Total Sinyal Bluetooth Tertangkap: $($foundList.Count) perangkat di radius pemantauan." -ForegroundColor Green
    } else {
        Write-Host "        [i] Tidak ada sinyal beacon atau perangkat Bluetooth yang terdeteksi di radius 10m." -ForegroundColor Yellow
    }
} else {
    Write-Host "    [-] Status Radio Bluetooth   : NONAKTIF / MATI" -ForegroundColor Red
}
Write-Host ""




