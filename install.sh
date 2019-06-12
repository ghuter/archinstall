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

if ping -c1 archlinux.org > /dev/null 2>&1; then
    echo "fix your network connection first"
    exit 1
fi

timedatectl set-ntp true

echo "Configure your partitions:"
echo "For example"
echo "BIOS with MBR: /"
echo "UEFI with GPT: /boot or /efi and /"
read -r
cfdisk
clear
echo "Enter the root partition / (for instance /dev/sda2): "
read -r root
echo "Enter the boot partition (leave blank if there are none): "
read -r boot

mount "$root" /mnt
if [ -n "$boot" ]; then
    mkdir /mnt/boot
    mount "$boot" /mnt/boot
fi

echo "Do you want to edit the mirror list ? [Y/n]: "
read -r ml

if [ "$ml" = "Y" ] || [ "$ml" = "y" ]; then
    vi /etc/pacman.d//mirrorlist
fi

pacstrap /mnt base

genfstab -U /mnt >> /mnt/etc/fstab

arch-root /mnt

clear
echo "Choose your region in:"
ls /usr/share/zoneinfo
read -r region
if [ ! -d /usr/share/zoneinfo/"$region" ]; then
    echo "Not existing. Skipping..."
else
    clear
    echo "Choose a city in :"
    ls /usr/share/zoneinfo/"$region"
    read -r city
fi

ln -sf /usr/share/zoneinfo/"$region"/"$city" /etc/localtime

hwclock --systohc

clear
echo "Uncomment en_US.UTF-8 UTF-8 and other needed locales..."
read -r
vi /etc/locale.gen

locale-gen

clear
echo "Enter LANG variable (for instance en_US.UTF-8): "
read -r lang
echo "$lang" > /etc/locale.conf

clear
echo "Choose keyboard layout in:"
read -r
find /usr/share/kbd/keymaps/ -type f -iname "*.map.gz" -exec basename {} \; | sed "s/.map.gz$//" | column | less
read -r kbd_lay
echo KEYMAP="$kbd_lay" > /etc/vconsole.conf

clear
echo "hostname: "
read -r hostname
echo "$hostname" > /etc/hostname
cat << EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.0.1   $hostname.localdomain   $hostname
EOF

clear
echo "Set the root password:"
passwd

clear
echo "amd or intel processor ? [a/i]"
read -r processor
[ "$processor" = "a" ] && pacman -S amd-ucode
[ "$processor" = "i" ] && pacman -S intel-ucode

clear
echo "Enter your disk name (/dev/sda): "
read -r disk
pacman -S grub os-prober
grub-install --target=i386-pc "$disk"
grub-mkconfig -o /boot/grub/grub.cfg

clear
echo "For nvidia drivers, see at https://wiki.archlinux.org/index.php/NVIDIA"

clear
echo "Installing Xorg..."
pacman -S xorg
echo "Setting keyboard layout..."
echo "Enter layout (usually a 2-letter country code): "
read -r layout
localectl set-x11-keymap "$layout"

clear
echo "Setting power management (handled by systemd):"
read -r
vi /etc/systemd/logind.conf

clear
echo "Adding some fonts..."
pacman -S terminus-font ttf-dejavu ttf-roboto noto-fonts ttf-ubuntu-font-family ttf-anonymous-pro ttf-inconsolata adobe-source-code-pro-fonts

clear
echo "Adding shells..."
sudo pacman -S zsh bash dash bash-completion
echo "Symlink /bin/sh to dash"
ln -s /bin/sh /usr/bin/dash

echo "New user name: "
read -r user
adduser -m -s /bin/zsh "$user"

echo "Installing the i3 WM..."
pacman -S i3-gaps

echo "Installing basic applications..."
pacman -S compton lxappearance sxhkd dmenu i3-scrot i3status dunst ffmpeg python-pywal mpv feh yaourt neofetch neovim htop
echo "Installing AUR apps..."
yaourt -S bmenu rofi-surfraw-git
echo "Installing additional apps..."
pacman -S mpd ncmpcpp mpc code firefox pcmanfm
yaourt -S google-chrome

