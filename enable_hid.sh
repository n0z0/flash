#!/system/bin/sh
# enable_hid.sh - Script untuk mengaktifkan USB Gadget HID (/dev/hidg0) di Android
# Kompatibel dengan LineageOS + Custom Kernel (SDM660 / SDM636 / DRG)

if [ "$(id -u)" != "0" ]; then
    echo "[-] Error: Script ini harus dijalankan sebagai ROOT (ketik 'su' terlebih dahulu)!"
    exit 1
fi

CONFIGFS_DIR="/config/usb_gadget/g1"

if [ ! -d "$CONFIGFS_DIR" ]; then
    echo "[-] Error: Direktori ConfigFS $CONFIGFS_DIR tidak ditemukan."
    echo "    Pastikan kernel mengaktifkan USB ConfigFS."
    exit 1
fi

UDC=$(getprop sys.usb.controller)
if [ -z "$UDC" ]; then
    UDC=$(ls /sys/class/udc 2>/dev/null | head -n 1)
fi

if [ -z "$UDC" ]; then
    echo "[-] Error: USB Device Controller (UDC) tidak terdeteksi."
    exit 1
fi

echo "[*] Mendeteksi UDC: $UDC"

# 1. Siapkan HID Keyboard (hid.keyboard -> /dev/hidg0)
HID_KB="$CONFIGFS_DIR/functions/hid.keyboard"
if [ ! -d "$HID_KB" ]; then
    echo "[*] Membuat fungsi hid.keyboard..."
    mkdir -p "$HID_KB"
    if [ $? -ne 0 ]; then
        echo "[-] Gagal membuat $HID_KB. Kemungkinan kernel tidak memiliki f_hid driver."
        exit 1
    fi
    echo 1 > "$HID_KB/subclass"
    echo 1 > "$HID_KB/protocol"
    echo 8 > "$HID_KB/report_length"
    
    # 63-byte USB HID standard Keyboard report descriptor
    printf '\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02\x95\x01\x75\x08\x81\x01\x95\x05\x75\x01\x05\x08\x19\x01\x29\x05\x91\x02\x95\x01\x75\x03\x91\x01\x95\x06\x75\x08\x15\x00\x25\x65\x05\x07\x19\x00\x29\x65\x81\x00\xc0' > "$HID_KB/report_desc"
fi

# 2. Hubungkan ke konfigurasi aktif
CONFIG_DIR=$(ls -d $CONFIGFS_DIR/configs/*.* 2>/dev/null | head -n 1)
if [ -z "$CONFIG_DIR" ]; then
    CONFIG_DIR="$CONFIGFS_DIR/configs/b.1"
    mkdir -p "$CONFIG_DIR"
fi

echo "[*] Konfigurasi target: $CONFIG_DIR"

if [ ! -e "$CONFIG_DIR/hid.keyboard" ]; then
    echo "[*] Menghubungkan fungsi hid.keyboard ke konfigurasi USB..."
    # Lepas UDC sejenak sebelum me-link fungsi
    echo "none" > "$CONFIGFS_DIR/UDC" 2>/dev/null || echo "" > "$CONFIGFS_DIR/UDC" 2>/dev/null
    ln -s "$HID_KB" "$CONFIG_DIR/hid.keyboard"
    echo "$UDC" > "$CONFIGFS_DIR/UDC"
fi

sleep 1

# 3. Validasi device node
if [ -c /dev/hidg0 ]; then
    chmod 666 /dev/hidg*
    echo "[+] BERHASIL! /dev/hidg0 aktif dan siap digunakan."
    ls -l /dev/hidg*
    
    # Tawarkan pasang ke Magisk boot service jika direktori ada
    if [ -d "/data/adb/service.d" ]; then
        cp "$0" /data/adb/service.d/enable_hid.sh 2>/dev/null
        chmod +x /data/adb/service.d/enable_hid.sh 2>/dev/null
        echo "[+] Telah dipasang ke /data/adb/service.d/ agar aktif otomatis setiap kali booting!"
    fi
else
    echo "[-] Device /dev/hidg0 belum muncul."
    echo "    Jalankan check_hid.sh untuk analisis lebih lanjut."
fi
