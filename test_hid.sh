#!/system/bin/sh
# Script pengujian USB Gadget HID untuk Nokia 6.1 Plus
# Mengirim tombol 'a' ke PC target

if [ ! -e /dev/hidg0 ]; then
    echo "[-] Error: /dev/hidg0 tidak ditemukan. Pastikan kernel mendukung USB Gadget HID."
    exit 1
fi

echo "[+] Mengirim keystroke 'a' ke /dev/hidg0..."
# Tekan tombol 'a' (Keycode 0x04)
echo -ne "\0\0\x04\0\0\0\0\0" > /dev/hidg0
# Lepas tombol (Key release)
echo -ne "\0\0\0\0\0\0\0\0" > /dev/hidg0
echo "[+] Selesai! Karakter 'a' berhasil dikirim ke PC."
