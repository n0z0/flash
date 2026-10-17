# Panduan Diagnostik & Debugging SIM Card / Modem via USB (ADB)

Dokumentasi ini merangkum seluruh investigasi teknis, akar penyebab (*root cause*), dan prosedur penyelesaian saat kartu SIM mengalami kendala sinyal (*No Service*, *Invalid Card*, *SIM Not Allowed*, atau *Mobile network not available*) pada Nokia 6.1 Plus (TA-1099 / DRG_sprout) yang menjalankan LineageOS 18.1 (Android 11).

---

## 1. Arsitektur Jaringan Seluler & Akar Masalah "No Service"

Di Android, koneksi seluler terbagi menjadi 2 domain terpisah:
1. **Domain CS (Circuit Switched):** Mengurus panggilan suara tradisional, SMS biasa, dan kode dial USSD (`*888#`, `*123#`).
2. **Domain PS (Packet Switched):** Mengurus data internet (4G LTE / GPRS).

### Mengapa Tampil "No Service" Padahal Sinyal Modem 100% Aman?
1. **Decommissioning 3G Nasional:** Seluruh operator di Indonesia (Telkomsel, Indosat, XL, Smartfren) telah **mematikan total jaringan 3G**. Jalur panggilan suara di 4G wajib melalui **VoLTE (Voice over LTE)**.
2. **Bug CarrierConfig di LineageOS (AOSP Generic):**
   * Secara bawaan, LineageOS menetapkan profil operator Indonesia ke:
     ```text
     carrier_volte_available_bool = false
     carrier_volte_provisioned_bool = false
     ```
   * **Dampak:** Karena VoLTE dinonaktifkan oleh sistem operasi, ketika modem mengunci sinyal 4G LTE, Android mendeteksi tidak ada jalur suara (`mVoiceRegState = 1 (OUT_OF_SERVICE)`).
   * Meskipun modem sebenarnya sudah terhubung ke tower operator (`mDataRegState = 0 (IN_SERVICE)` dan `rejectCause = 0`), **SystemUI Android tetap menampilkan label "No service"** di status bar dan panel notifikasi karena memprioritaskan ketersediaan layanan suara (*Voice State*).

---

## 2. Solusi: Injeksi Konfigurasi VoLTE via ADB

Jalankan perintah ini di terminal PC untuk membuka kunci VoLTE secara permanen di database Android:

```powershell
# Buka kunci VoLTE untuk Slot 1 (Slot ID 0)
.\repartition_tool\adb.exe shell "su -c 'cmd phone cc set-value -s 0 -p carrier_volte_available_bool true'"
.\repartition_tool\adb.exe shell "su -c 'cmd phone cc set-value -s 0 -p carrier_volte_provisioned_bool true'"
.\repartition_tool\adb.exe shell "su -c 'cmd phone cc set-value -s 0 -p carrier_wfc_ims_available_bool true'"

# Buka kunci VoLTE untuk Slot 2 (Slot ID 1)
.\repartition_tool\adb.exe shell "su -c 'cmd phone cc set-value -s 1 -p carrier_volte_available_bool true'"
.\repartition_tool\adb.exe shell "su -c 'cmd phone cc set-value -s 1 -p carrier_volte_provisioned_bool true'"
.\repartition_tool\adb.exe shell "su -c 'cmd phone cc set-value -s 1 -p carrier_wfc_ims_available_bool true'"

# Pastikan persist properties modem aktif
.\repartition_tool\adb.exe shell "su -c 'setprop persist.dbg.volte_avail_ovr 1; setprop persist.dbg.vt_avail_ovr 1; setprop persist.dbg.wfc_avail_ovr 1'"
```

Setelah perintah dijalankan:
* Menu toggle **VoLTE** akan otomatis muncul dan aktif di **Settings ➔ Network & internet ➔ Mobile network**.
* Lakukan **Reboot / Restart HP** agar modem daemon (`qcrild`, `imsqmidaemon`, RIL) menginisialisasi ulang IMS bearer dari awal booting.

---

## 3. Cheat Sheet Perintah Diagnostik ADB

### A. Cek Status Fisik SIM Tray & Deteksi Kartu
```powershell
# Cek apakah kartu terbaca hardware (LOADED / ABSENT / CARD_IO_ERROR)
.\repartition_tool\adb.exe shell "su -c 'dumpsys telephony.registry | grep -iE \"mSimState|mCardState\"'"

# Cek ICCID fisik kartu yang aktif di slot 0 dan slot 1
.\repartition_tool\adb.exe shell "su -c 'cat /data/vendor/radio/iccid_0; echo \"---\"; cat /data/vendor/radio/iccid_1'"
```
* **Keterangan Nilai `mSimState`:**
  * `LOADED`: Kartu SIM normal dan terbaca sempurna oleh modem.
  * `ABSENT`: Slot tray kosong.
  * `CARD_IO_ERROR`: Terjadi gagal kontak elektrik fisik (*Invalid Card*). Solusi: cabut tray, bersihkan kuningan kartu SIM, dan masukkan kembali secara presisi.

---

### B. Cek Status Registrasi Jaringan & Reject Cause (3GPP)
```powershell
.\repartition_tool\adb.exe shell "su -c 'dumpsys telephony.registry | grep -E \"mVoiceRegState|mDataRegState|mOperatorAlpha|CellIdentityLte\"'"
```
* **Status Domain:**
  * `mDataRegState = 0 (IN_SERVICE)`: Jalur paket data 4G terdaftar normal.
  * `mVoiceRegState = 1 (OUT_OF_SERVICE)`: Panggilan suara offline (penyebab USSD `*888#` gagal).
* **Nilai `rejectCause` 3GPP:**
  * `rejectCause = 0`: **NORMAL**. Tidak ada pemblokiran dari tower maupun operator.
  * `rejectCause = 6 (Illegal ME)`: **IMEI DIBLOKIR**. Perangkat ditolak masuk jaringan oleh operator/CEIR.
  * `rejectCause = 14 / 15`: Layanan EPS / sel 2G-3G tidak tersedia di tracking area ini (*Location Area Not Allowed*).

---

### C. Cek Status IMS / VoLTE & CarrierConfig
```powershell
# Cek nilai CarrierConfig VoLTE saat ini
.\repartition_tool\adb.exe shell "su -c 'cmd phone cc get-value carrier_volte_available_bool'"

# Cek registrasi IMS di telephony service
.\repartition_tool\adb.exe shell "su -c 'dumpsys telephony.registry | grep -i ims'"

# Cek daemon IMS Qualcomm
.\repartition_tool\adb.exe shell "su -c 'getprop | grep -iE \"volte|ims|vowifi\"'"
```

---

### D. Cek & Ubah Mode Jaringan (Preferred Network Mode)
```powershell
# Cek mode saat ini
.\repartition_tool\adb.exe shell "settings get global preferred_network_mode"

# Ubah ke mode 9 (LTE / WCDMA / GSM Auto) agar bisa fallback ke 2G
.\repartition_tool\adb.exe shell "su -c 'settings put global preferred_network_mode 9,9; settings put global preferred_network_mode1 9'"
```

---

## 4. Konfigurasi Dual SIM (Slot 1 & Slot 2)

Nokia 6.1 Plus memiliki 2 nomor IMEI fisik bawaan pabrik:
* **Slot 1:** `353384090120438`
* **Slot 2:** `353384090620437`

Kedua slot mendukung mode Dual SIM Standby (DSDS).
* Anda dapat memasukkan kartu **Telkomsel di Slot 1** dan **XL di Slot 2** secara bersamaan.
* Pengaturan SIM default untuk Panggilan, SMS, dan Mobile Data dapat diatur langsung melalui menu **Settings ➔ Network & internet ➔ SIM cards / Mobile network**.

---

## 5. Mitos vs Fakta Cek IMEI (Bea Cukai & Kemenperin)

| Database | Sasaran Perangkat | Keterangan |
| :--- | :--- | :--- |
| **Bea Cukai** (`beacukai.go.id`) | **Hanya HP bawaan penumpang dari luar negeri** yang didaftarkan di bandara/pelabuhan. | HP resmi lokal (TAM/Erajaya) dan HP lama (sebelum 15 Sept 2020) **pasti berstatus "IMEI Tidak Ditemukan"**. Ini normal. |
| **Kemenperin** (`imei.kemenperin.go.id`) | HP resmi yang diproduksi/diimpor distributor berizin di Indonesia. | Sering mengalami maintenance database. |
| **CEIR (Pusat Operator)** | Database operasional aktif seluruh operator di Indonesia. | Validasi nyata langsung terlihat saat SIM dimasukkan: jika tower mengunci sinyal (`rejectCause = 0`), berarti **IMEI 100% aman dan tidak diblokir**. |
