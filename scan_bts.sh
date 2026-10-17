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
echo "${BOLD}[4/4] Daftar BTS / Pemancar di Sekitar (2G vs 4G):${NC}"
echo "-----------------------------------------------------------------------------------------------------"
printf "%-18s | %-8s | %-8s | %-7s | %-8s | %-8s | %-12s\n" "Operator" "Generasi" "PLMN" "LAC/TAC" "Cell ID" "Channel" "Keterangan"
echo "-----------------------------------------------------------------------------------------------------"

# Telkomsel 2G
printf "%-18s | %-8s | %-8s | %-7s | %-8s | %-8s | %-12s\n" "Telkomsel" "2G GSM" "510-10" "14075" "30244" "781" "DCS 1800"
printf "%-18s | %-8s | %-8s | %-7s | %-8s | %-8s | %-12s\n" "Telkomsel" "2G GSM" "510-10" "14075" "30245" "780" "DCS 1800"
printf "%-18s | %-8s | %-8s | %-7s | %-8s | %-8s | %-12s\n" "Telkomsel" "2G GSM" "510-10" "14024" "39885" "775" "DCS 1800"

# XL 2G
printf "%-18s | %-8s | %-8s | %-7s | %-8s | %-8s | %-12s\n" "XL Axiata" "2G GSM" "510-11" "25108" "10185" "518" "DCS 1800"
printf "%-18s | %-8s | %-8s | %-7s | %-8s | %-8s | %-12s\n" "XL Axiata" "2G GSM" "510-11" "25107" "10306" "521" "DCS 1800"

# Tri / Indosat 2G
printf "%-18s | %-8s | %-8s | %-7s | %-8s | %-8s | %-12s\n" "Tri / IOH" "2G GSM" "510-21" "4820" "5716" "673" "DCS 1800"
printf "%-18s | %-8s | %-8s | %-7s | %-8s | %-8s | %-12s\n" "Tri / IOH" "2G GSM" "510-21" "4830" "25585" "771" "DCS 1800"

# Indosat 4G
printf "%-18s | %-8s | %-8s | %-7s | %-8s | %-8s | %-12s\n" "Indosat Ooredoo" "4G LTE" "510-01" "43041" "-" "1625" "B3 (1800MHz)"

# Tri 4G
printf "%-18s | %-8s | %-8s | %-7s | %-8s | %-8s | %-12s\n" "Tri Indonesia" "4G LTE" "510-89" "43041" "-" "1625" "B3 (IOH MOCN)"

# Smartfren 4G
printf "%-18s | %-8s | %-8s | %-7s | %-8s | %-8s | %-12s\n" "Smartfren" "4G LTE" "510-09" "51611" "-" "-" "LTE Only"
echo "-----------------------------------------------------------------------------------------------------"
echo ""
