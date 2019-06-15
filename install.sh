#!/bin/sh

if [ "$(id -g)" != "0" ]; then
    echo "You are not root !"
    exit 1
fi

# Asuming the keyboard layout is 'azerty'
# otherwise choose a file from /usr/share/kbd/keymaps/*/*.map.gz
loadkeys fr-pc

#is_in_uefi=1

if [ ! -d /sys/firmware/efi/efivars ]; then
    #is_in_uefi=0
    echo "BIOS mode detected"
fi

if ! ping -c1 archlinux.org > /dev/null 2>&1; then
    echo "fix your network connection first"
    exit 1
fi

timedatectl set-ntp true

echo "Configure your partitions:"
echo "For example"
echo "BIOS with MBR: /boot and /"
echo "UEFI with GPT: /boot or /efi and /"
echo "[Press enter to continue]"
read -r
cfdisk
clear
echo "Enter the root partition / (for instance /dev/sda2): "
read -r root
echo "Enter the boot partition: "
read -r boot

mkfs.ext4 "$root"
mkfs.ext4 "$boot"

mount "$root" /mnt
mkdir /mnt/boot
mount "$boot" /mnt/boot

echo "Do you want to edit the mirror list ? [Y/n]: "
read -r ml

if [ "$ml" = "Y" ] || [ "$ml" = "y" ]; then
    vi /etc/pacman.d/mirrorlist
fi

pacman -Sy
pacstrap /mnt base

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt sh -c "$(curl -fsSL https://github.com/ghuter/archinstall/raw/master/chroot_cmds.sh)"

echo "Do you want to reboot now ? [Y/n]"
read -r rb
if [ "$rb" = "Y" ] || [ "$rb" = "y" ]; then
    reboot
fi

