#!/bin/bash

# time
ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
hwclock --systohc

# locale
if grep -q "^#.*en_US.UTF-8 UTF-8" /etc/locale.gen; then
    sudo sed -i "s/^#.*en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen
fi

locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

# hostname
echo "natan-arch" > /etc/hostname

# network
systemctl enable NetworkManager.service

# lib32
if grep -q "^#\[multilib\]" /etc/pacman.conf; then
    # Uncomment the [multilib] section by removing the leading #
    sudo sed -i "s/^#\[multilib\]/\[multilib\]/" /etc/pacman.conf
fi
if grep -q "^#Include = /etc/pacman.d/mirrorlist" /etc/pacman.conf; then
    # Uncomment the #Include line by removing the leading #
    sudo sed -i "s/^#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/" /etc/pacman.conf
fi

# users
useradd -m -g users -G wheel,storage,power -s /bin/bash natan
passwd
passwd natan

if grep -q "^# %wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
    sed -i "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers
fi

# efi vars
mount -t efivarfs efivarfs /sys/firmware/efi/efivars/

# nvidia
sudo pacman -S --noconfirm nvidia-dkms libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings
mkdir /etc/pacman.d/hooks
mv ./nvidia.hook /etc/pacman.d/hooks/nvidia.hook

newmodules="nvidia nvidia_modeset nvidia_uvm nvidia_drm"

if grep -q "^MODULES=(" /etc/mkinitcpio.conf; then
    sudo sed -i "s/^MODULES=(/MODULES=($newmodules/" /etc/mkinitcpio.conf
fi

# bootloader setup
EFIpart=$(findmnt -n -o SOURCE /boot)
mkdir /boot/EFI
mkdir /boot/EFI/BOOT
mv ./limine.hook /etc/pacman.d/hooks/limine.hook
cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI
efibootmgr --create --disk "$EFIpart" --part 1 --loader '\EFI\BOOT\BOOTX64.EFI' --label 'Limine Boot Manager' --unicode
