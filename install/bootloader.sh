#!/bin/bash

ROOTpart="$1"
UUID=$(lsblk -dno UUID "/dev/$ROOTpart")

if grep -q "^    CMDLINE=root=UUID=" ./limine.cfg; then
    sudo sed -i "s/^    CMDLINE=root=UUID=[^ ]*/    CMDLINE=root=UUID=$UUID/" ./limine.cfg
fi
