#!/bin/bash

# check if running in UEFI
if [ ! -f /sys/firmware/efi/fw_platform_size ]; then
    echo "ERROR: Running in BIOS mode"
    exit 1
fi

isUEFI=$(cat /sys/firmware/efi/fw_platform_size)
if [ "$isUEFI" != "64" ]; then
    echo "ERROR: Not running in 64 UEFI"
    exit 1
fi

# check for internet connection
if ! ping -c 1 -W 1 archlinux.org > /dev/null 2>&1; then
    echo "ERROR: Not connected to the internet"
    exit 1
fi
