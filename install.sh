#!/bin/bash
# uwubright

# TODO:
# 1. UUID is not saved into limine.cfg
# 2. bootloadersetup is broken 1. might be the reason

# stop after an error
set -e

# make scripts executable
find ./install -name "*.sh" -exec chmod +x {} \;

# run before install checks
./install/check.sh

# set timezone
timedatectl set-timezone Europe/Warsaw
timedatectl

# format partitions
./install/partitions.sh

# setup mirror list
pacman -S --noconfirm reflector
reflector --country Poland,Germany --sort rate --latest 10 --number 35 --save /etc/pacman.d/mirrorlist

# install essential packages
yes | pacstrap -K /mnt base linux linux-headers linux-firmware intel-ucode limine efibootmgr pulseaudio pulseaudio-bluetooth networkmanager vim sudo

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

# copy limine.cfg
sleep 5
read -p "Enter ROOT partition: " ROOTpart
UUID=$(lsblk -dno UUID "/dev/$ROOTpart")

if grep -q "^    CMDLINE=root=UUID=" ./limine.cfg; then
    sudo sed -i "s/^    CMDLINE=root=UUID=[^ ]*/    CMDLINE=root=UUID=$UUID/" ./limine.cfg
fi

cp ./install/limine.cfg /mnt/boot/limine.cfg

# continue install in chroot
cp ./install/chroot-install.sh /mnt/install.sh
cp ./install/nvidia.hook /mnt/nvidia.hook
cp ./install/limine.hook /mnt/limine.hook
cp ./install/pacman.conf /mnt/pacman.conf
arch-chroot /mnt /bin/bash /install.sh
