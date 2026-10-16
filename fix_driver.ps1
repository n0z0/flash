$devicePath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\VID_2E04&PID_C009\DRGGAM2853102118\Device Parameters"
if (Test-Path $devicePath) {
    Set-ItemProperty -Path $devicePath -Name "DeviceInterfaceGUIDs" -Value @("{F72FE0D4-CBCB-407d-8814-9ED673D0DD6B}", "{F7275995-2E0E-480E-8311-137B953EC1ED}")
}
pnputil /restart-device "USB\VID_2E04&PID_C009\DRGGAM2853102118"
