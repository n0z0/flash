#!/system/bin/sh
# check_sim.sh - Diagnostik Jaringan Seluler & Modem Nokia 6.1 Plus

echo "=========================================="
echo "    DIAGNOSTIK KARTU SIM & SINYAL RADIO   "
echo "=========================================="

echo "\n[1] Informasi Modem & Baseband:"
getprop gsm.version.baseband
getprop ro.boot.baseband

echo "\n[2] Status SIM Card (UICC):"
echo "SIM 1 State: $(getprop gsm.sim.state)"
echo "Operator Numeric: $(getprop gsm.operator.numeric)"
echo "Operator Name: $(getprop gsm.operator.alpha)"

echo "\n[3] Status Registrasi Jaringan (dumpsys):"
dumpsys telephony.registry 2>/dev/null | grep -E "mVoiceRegState|mDataRegState|mOperatorAlphaLong|mCellInfo" | head -n 15

echo "\n[4] Analisis Penolakan Jaringan (Radio Log Reject Causes):"
logcat -b radio -d 2>/dev/null | grep -iE "reject|cause|illegal|not_allowed|denied|forbidden" | tail -n 15

echo "=========================================="
