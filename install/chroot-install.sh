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
# Define the path to the configuration file
configfile="/etc/pacman.conf"

# Find the line number of the [multilib] section
multilib_line=$(awk '/^\[multilib\]/ {print NR; exit}' "$configfile")

# Debugging: Print the line number of [multilib]
echo "Line number of [multilib]: $multilib_line"

# Check if the [multilib] section exists
if [ -n "$multilib_line" ]; then
    # Print the line immediately following [multilib]
    next_line=$(sed -n "$((multilib_line + 1))p" "$configfile")
    echo "Line immediately following [multilib]: $next_line"

    # Check if the next line is commented out Include line and uncomment it
    if [[ "$next_line" =~ ^#Include\ =\ /etc/pacman.d/mirrorlist$ ]]; then
        echo "Uncommenting the Include line."
        sudo sed -i "$((multilib_line + 1))s/^#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/" "$configfile"
    else
        echo "The next line is not the expected #Include line."
    fi
else
    echo "[multilib] section not found in $configfile."
fi

pacman -Syu --noconfirm

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
EFIdevicename="${EFIpart%[0-9]*}"
mkdir /boot/EFI
mkdir /boot/EFI/BOOT
mv ./limine.hook /etc/pacman.d/hooks/limine.hook
cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI
efibootmgr --create --disk "$EFIdevicename" --part 1 --loader '\EFI\BOOT\BOOTX64.EFI' --label 'Limine Boot Manager' --unicode
