#!/system/bin/sh
# badusb.sh - Menu Shortcut Cepat BadUSB untuk Nokia 6.1 Plus

while true; do
    echo "======================================"
    echo "       NOKIA 6.1 PLUS BADUSB MENU     "
    echo "======================================"
    echo "1. Tekan Tombol Windows (Start)"
    echo "2. Buka Dialog Run (Win + R)"
    echo "3. Buka File Explorer (Win + E)"
    echo "4. Buka Task Manager (Ctrl+Shift+Esc)"
    echo "5. Tutup Aplikasi Aktif (Alt + F4)"
    echo "6. Buka Notepad & Ketik Pesan"
    echo "7. Buka Command Prompt (CMD)"
    echo "8. Ctrl + Alt + Del"
    echo "9. Ketik Kalimat Bebas"
    echo "0. Keluar"
    echo "======================================"
    printf "Pilih menu [0-9]: "
    read opt

    case "$opt" in
        1)
            echo "[*] Mengirim tombol WINDOWS..."
            hid-keyboard GUI
            ;;
        2)
            echo "[*] Mengirim Win + R..."
            hid-keyboard GUI-r
            ;;
        3)
            echo "[*] Mengirim Win + E..."
            hid-keyboard GUI-e
            ;;
        4)
            echo "[*] Mengirim Ctrl + Shift + Esc..."
            hid-keyboard CTRL-SHIFT-ESC
            ;;
        5)
            echo "[*] Mengirim Alt + F4..."
            hid-keyboard ALT-F4
            ;;
        6)
            echo "[*] Membuka Notepad..."
            hid-keyboard GUI-r
            sleep 0.8
            hid-keyboard "notepad"
            sleep 0.5
            hid-keyboard ENTER
            sleep 1
            hid-keyboard "Halo dari Nokia 6.1 Plus BadUSB!"
            ;;
        7)
            echo "[*] Membuka CMD..."
            hid-keyboard GUI-r
            sleep 0.8
            hid-keyboard "cmd"
            sleep 0.5
            hid-keyboard ENTER
            ;;
        8)
            echo "[*] Mengirim Ctrl + Alt + Del..."
            hid-keyboard CTRL-ALT-DEL
            ;;
        9)
            printf "Masukkan kalimat yang ingin diketik: "
            read teks
            hid-keyboard "$teks"
            printf "Tekan Enter di target? (y/n): "
            read enter_opt
            if [ "$enter_opt" = "y" ] || [ "$enter_opt" = "Y" ]; then
                hid-keyboard ENTER
            fi
            ;;
        0)
            echo "Keluar."
            break
            ;;
        *)
            echo "Pilihan tidak valid!"
            ;;
    esac
    echo ""
    sleep 1
done
