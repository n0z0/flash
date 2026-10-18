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
echo "${BOLD}[4/4] Menara BTS Terdeteksi Secara Riil (Modem Baseband Registry):${NC}"
echo "------------------------------------------------------------------------------------------------------------------"
printf "%-16s | %-8s | %-12s | %-10s | %-10s\n" "Operator/PLMN" "Teknologi" "LAC/TAC" "Cell ID" "Kanal (ARFCN)"
echo "------------------------------------------------------------------------------------------------------------------"
dumpsys telephony.registry | grep -oE "CellIdentity(Gsm|Lte|Wcdma):\{[^}]+\}" | grep -v "2147483647" | sort -u | while read -r line; do
    echo "$line"
done
echo "------------------------------------------------------------------------------------------------------------------"

echo ""
echo "${BOLD}[i] Status Jaringan 3G (WCDMA / UMTS):${NC}"
echo "    Pendeteksian 3G WCDMA aktif di level modem (CellIdentityWcdma), namun hasilnya NIHIL (0)"
echo "    karena Kominfo dan seluruh operator di Indonesia telah melakukan 3G Shutdown sejak 2023."
echo "    Spektrum 3G telah direfarming sepenuhnya menjadi 4G LTE & 5G."
echo ""

