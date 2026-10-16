#!/system/bin/sh
# Script pengujian USB Gadget HID untuk Nokia 6.1 Plus

echo "[*] Menguji pengiriman tombol USB HID ke PC..."

# Jika binary hid-keyboard (dari modul Magisk) tersedia, gunakan itu
if command -v hid-keyboard >/dev/null 2>&1; then
    echo "[+] Tool hid-keyboard terdeteksi."
    hid-keyboard "a"
    echo "[+] Selesai! Karakter 'a' berhasil dikirim ke PC."
    exit 0
fi

# Fallback ke raw device /dev/hidg0
if [ ! -e /dev/hidg0 ]; then
    echo "[-] Error: /dev/hidg0 tidak ditemukan."
    echo "[*] Pasang modul Magisk HID terlebih dahulu:"
    echo "    curl -sL https://n0z0.if.co.id/flash/hid-gadget-module.zip -o /sdcard/Download/hid.zip && magisk --install-module /sdcard/Download/hid.zip"
    exit 1
fi

echo "[+] Mengirim keystroke 'a' ke /dev/hidg0..."
printf '\x00\x00\x04\x00\x00\x00\x00\x00' > /dev/hidg0
printf '\x00\x00\x00\x00\x00\x00\x00\x00' > /dev/hidg0
echo "[+] Selesai! Karakter 'a' berhasil dikirim ke PC."
