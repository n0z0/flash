#!/system/bin/sh
echo "=== IMS REGISTRATION & VOLTE STATUS ==="
dumpsys telephony.registry | grep -i ims
echo "=== RADIO & VOLTE PROPS ==="
getprop | grep -iE 'volte|ims|vowifi'
echo "=== PREFERRED NETWORK MODE ==="
settings get global preferred_network_mode
settings get global preferred_network_mode1
echo "=== APN LIST IN TELEPHONY DB ==="
content query --uri content://telephony/carriers/current
