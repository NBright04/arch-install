#!/bin/bash

check_partition() {
    local partition=$1

    if lsblk | grep -q "^${partition} "; then
        return 0
    elif [ -e "/dev/$partition" ]; then
        return 0
    else
        echo "ERROR: Partition /dev/$partition does not exist"
        exit 1
    fi
}

# get partition names from user and check if they exist
read -p "Enter EFI partition: " EFIpart
read -p "Enter ROOT partition: " ROOTpart
read -p "Enter HOME partition: " HOMEpart
read -p "Enter SWAP partition: " SWAPpart

check_partition "$EFIpart"
check_partition "$ROOTpart"
check_partition "$HOMEpart"
check_partition "$SWAPpart"

# format partitions and mount them
mkfs.fat -F 32 "/dev/$EFIpart"
mkfs.ext4 "/dev/$ROOTpart"
mkfs.ext4 "/dev/$HOMEpart"
mkswap "/dev/$SWAPpart"

mount "/dev/$ROOTpart" /mnt
mount --mkdir "/dev/$EFIpart" /mnt/boot
mount --mkdir "/dev/$HOMEpart" /mnt/home
swapon "/dev/$SWAPpart"

# bootloader preconfig
UUID=$(lsblk -dno UUID "/dev/$ROOTpart")

if grep -q "^    CMDLINE=root=UUID=" ./limine.cfg; then
    sudo sed -i "s/^    CMDLINE=root=UUID=[^ ]*/    CMDLINE=root=UUID=$UUID/" ./limine.cfg
fi
