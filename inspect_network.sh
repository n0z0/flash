#!/system/bin/sh
echo "=== Preferred Network Modes ==="
settings get global preferred_network_mode
settings get global preferred_network_mode1
settings get global preferred_network_mode2

echo "=== Telephony Properties ==="
getprop | grep -iE 'telephony|volte|ims|lte|operator|radio'

echo "=== APN List ==="
content query --uri content://telephony/carriers/current 2>/dev/null | head -n 10
