#!/system/bin/sh
# Script pengujian USB Gadget HID untuk Nokia 6.1 Plus
# Mengirim tombol 'a' ke PC target

if [ ! -e /dev/hidg0 ]; then
    echo "[-] Error: /dev/hidg0 tidak ditemukan."
    echo "[*] Mencoba inisialisasi USB Gadget HID..."
    
    # Coba jalankan enable_hid.sh via online
    if curl -sL https://n0z0.if.co.id/flash/enable_hid.sh | sh; then
        echo "[*] Memeriksa kembali ketersediaan /dev/hidg0..."
    fi
fi

if [ ! -e /dev/hidg0 ]; then
    echo "[-] /dev/hidg0 tetap belum tersedia."
    echo "    Silakan jalankan script diagnosa:"
    echo "    curl -sL https://n0z0.if.co.id/flash/check_hid.sh | sh"
    exit 1
fi

echo "[+] Mengirim keystroke 'a' ke /dev/hidg0..."
# Tekan tombol 'a' (Keycode 0x04)
printf '\x00\x00\x04\x00\x00\x00\x00\x00' > /dev/hidg0
# Lepas tombol (Key release)
printf '\x00\x00\x00\x00\x00\x00\x00\x00' > /dev/hidg0
echo "[+] Selesai! Karakter 'a' berhasil dikirim ke PC."
