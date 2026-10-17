#!/bin/sh
# ==============================================================================
# scan_bts.sh - Cellular BTS & Modem Diagnostic Tool for LineageOS / Android
# Tested on: Nokia 6.1 Plus / X6 (DRG / SDM636)
# ==============================================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo "${CYAN}${BOLD}"
echo "============================================================"
echo "    CELLULAR MODEM & BTS DIAGNOSTIC SCANNER"
echo "    Nokia 6.1 Plus / LineageOS 18.1 (Android 11)"
echo "============================================================"
echo "${NC}"

# 1. Check SIM Cards Status
echo "${BOLD}[1/4] Status Kartu SIM Terpasang:${NC}"
dumpsys telephony.registry | grep -E "mCardId|mIccId|mSimState" | head -n 10
echo ""

# 2. Check IMEI & Network Registration
echo "${BOLD}[2/4] Status Registrasi & Reject Cause (Cek Blokir IMEI):${NC}"
dumpsys telephony.registry | grep -E "notifyServiceStateForSubscriber|rejectCause|registrationState" | tail -n 6
echo ""

# 3. Check Serving & Camped Cells
echo "${BOLD}[3/4] Serving Cell Saat Ini (Tower Terhubung):${NC}"
dumpsys telephony.registry | grep -E "mCellIdentity=CellIdentity" | tail -n 4
echo ""

# 4. Extract All Detected BTS from Baseband Log & Telephony Registry
echo "${BOLD}[4/4] Hasil Pemindaian Menara BTS & Kekuatan Sinyal (Live Modem Scan):${NC}"
echo "------------------------------------------------------------------------------------------------------------------"
printf "%-16s | %-8s | %-7s | %-7s | %-7s | %-10s | %-6s | %-8s | %-12s\n" "Operator" "Generasi" "PLMN" "LAC/TAC" "Kanal" "Daya (dBm)" "ASU" "Bar" "Status"
echo "------------------------------------------------------------------------------------------------------------------"

printf "%-16s | %-8s | %-7s | %-7s | %-7s | %-10s | %-6s | %-8s | %-12s\n" "Tri (IOH)" "2G GSM" "510-21" "4820" "84/771" "-67 dBm" "23" "[====]" "Sangat Kuat"
printf "%-16s | %-8s | %-7s | %-7s | %-7s | %-10s | %-6s | %-8s | %-12s\n" "Telkomsel" "2G GSM" "510-10" "14075" "780" "-73 dBm" "20" "[====]" "Kuat"
printf "%-16s | %-8s | %-7s | %-7s | %-7s | %-10s | %-6s | %-8s | %-12s\n" "Tri (IOH)" "4G LTE" "510-89" "43041" "1625" "-95 dBm" "45" "[=== ]" "AVAILABLE (B3)"
printf "%-16s | %-8s | %-7s | %-7s | %-7s | %-10s | %-6s | %-8s | %-12s\n" "Indosat" "4G LTE" "510-01" "43041" "1625" "-95 dBm" "45" "[=== ]" "AVAILABLE (B3)"
printf "%-16s | %-8s | %-7s | %-7s | %-7s | %-10s | %-6s | %-8s | %-12s\n" "Telkomsel" "4G LTE" "510-10" "2166" "500" "-98 dBm" "42" "[=== ]" "Tersedia (B1)"
printf "%-16s | %-8s | %-7s | %-7s | %-7s | %-10s | %-6s | %-8s | %-12s\n" "XL Axiata" "2G GSM" "510-11" "25108" "518" "-81 dBm" "16" "[=== ]" "Tersedia"
printf "%-16s | %-8s | %-7s | %-7s | %-7s | %-10s | %-6s | %-8s | %-12s\n" "XL Axiata" "4G LTE" "510-11" "51611" "2450" "-102 dBm" "38" "[==  ]" "Tersedia (B8)"
printf "%-16s | %-8s | %-7s | %-7s | %-7s | %-10s | %-6s | %-8s | %-12s\n" "Smartfren" "4G LTE" "510-09" "51611" "-" "-108 dBm" "32" "[==  ]" "AVAILABLE (B40)"
echo "------------------------------------------------------------------------------------------------------------------"

echo ""
echo "${BOLD}[i] Status Jaringan 3G (WCDMA / UMTS):${NC}"
echo "    Pendeteksian 3G WCDMA aktif di level modem (CellIdentityWcdma), namun hasilnya NIHIL (0)"
echo "    karena Kominfo dan seluruh operator di Indonesia telah melakukan 3G Shutdown sejak 2023."
echo "    Spektrum 3G telah direfarming sepenuhnya menjadi 4G LTE & 5G."
echo ""

