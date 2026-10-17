#!/system/bin/sh
# Fix Network & APN Configuration for LineageOS on Nokia 6.1 Plus / X6

echo "[1/5] Memperbarui Protokol APN ke IPv4/IPv6..."
# Update APN directly via SQLite or ContentProvider
sqlite3 /data/user_de/0/com.android.providers.telephony/databases/telephony.db "UPDATE carriers SET protocol='IPV4V6', roaming_protocol='IPV4V6' WHERE numeric IN ('51011', '51010', '51089', '51001');"

echo "[2/5] Mengaktifkan VoLTE & VoWiFi CarrierConfig..."
cmd phone cc set-value -s 0 -p carrier_volte_available_bool true
cmd phone cc set-value -s 0 -p carrier_volte_provisioned_bool true
cmd phone cc set-value -s 0 -p carrier_wfc_ims_available_bool true
cmd phone cc set-value -s 1 -p carrier_volte_available_bool true
cmd phone cc set-value -s 1 -p carrier_volte_provisioned_bool true
cmd phone cc set-value -s 1 -p carrier_wfc_ims_available_bool true

echo "[3/5] Mengaktifkan Persist Properties Modem Qualcomm..."
setprop persist.dbg.volte_avail_ovr 1
setprop persist.dbg.vt_avail_ovr 1
setprop persist.dbg.wfc_avail_ovr 1
setprop persist.radio.rat_on 1
setprop persist.radio.data_ltd_sys_ind 1

echo "[4/5] Menyetel Mode Jaringan & Data SubId Utama ke Slot 1..."
settings put global mobile_data 1
settings put global multi_sim_data_call 4
settings put global preferred_network_mode 9
settings put global preferred_network_mode4 9
settings put global preferred_network_mode3 9

echo "[5/5] Me-refresh Radio Modem..."
cmd connectivity airplane-mode enable
sleep 3
cmd connectivity airplane-mode disable
sleep 5

echo "Selesai! Status APN XL saat ini:"
sqlite3 /data/user_de/0/com.android.providers.telephony/databases/telephony.db "SELECT _id, name, numeric, apn, protocol, roaming_protocol, current FROM carriers WHERE numeric='51011' AND current=1;"
