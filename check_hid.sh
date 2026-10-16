#!/system/bin/sh
# check_hid.sh - Diagnostik USB HID & Kernel untuk Nokia 6.1 Plus

echo "=========================================="
echo "    DIAGNOSTIK KERNEL & USB GADGET HID    "
echo "=========================================="

echo "\n[1] Informasi Kernel:"
uname -a

echo "\n[2] Status Kernel Config (CONFIG_USB_CONFIGFS_F_HID):"
if [ -f /proc/config.gz ]; then
    zcat /proc/config.gz | grep -E "CONFIG_USB_CONFIGFS|CONFIG_USB_F_HID|CONFIG_USB_G_HID" || echo "[-] Opsi HID tidak ditemukan di config.gz"
elif [ -f /boot/config ]; then
    grep -E "CONFIG_USB_CONFIGFS|CONFIG_USB_F_HID|CONFIG_USB_G_HID" /boot/config
else
    echo "[*] /proc/config.gz tidak tersedia di kernel saat ini."
fi

echo "\n[3] Direktori ConfigFS:"
if [ -d /config/usb_gadget/g1 ]; then
    echo "[+] /config/usb_gadget/g1 ditemukan!"
    echo "Fungsi USB yang terpasang:"
    ls -la /config/usb_gadget/g1/functions 2>/dev/null
    echo "Konfigurasi aktif:"
    ls -la /config/usb_gadget/g1/configs/* 2>/dev/null
else
    echo "[-] /config/usb_gadget/g1 TIDAK ditemukan."
fi

echo "\n[4] USB Controller (UDC):"
getprop sys.usb.controller
ls /sys/class/udc 2>/dev/null

echo "\n[5] Device Node HID:"
if ls /dev/hidg* 1>/dev/null 2>&1; then
    ls -la /dev/hidg*
    echo "[+] HID Device node SUDAH TERSEDIA!"
else
    echo "[-] /dev/hidg* belum tersedia (perlu diaktifkan via ConfigFS)."
fi
echo "=========================================="
