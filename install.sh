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
echo "BIOS with MBR: /"
echo "UEFI with GPT: /boot or /efi and /"
echo "[Press enter to continue]"
read -r
cfdisk
clear
echo "Enter the root partition / (for instance /dev/sda2): "
read -r root
echo "Enter the boot partition (leave blank if there are none): "
read -r boot

mkfs.ext4 "$root"
[ -n "$boot" ] && mkfs.ext4 "$boot"

mount "$root" /mnt
if [ -n "$boot" ]; then
    mkdir /mnt/boot
    mount "$boot" /mnt/boot
fi

echo "Do you want to edit the mirror list ? [Y/n]: "
read -r ml

if [ "$ml" = "Y" ] || [ "$ml" = "y" ]; then
    vi /etc/pacman.d/mirrorlist
fi

pacman -Sy
pacstrap /mnt base

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

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
echo "[Press enter to continue]"
read -r
vi /etc/locale.gen

locale-gen

clear
echo "Enter LANG variable (for instance en_US.UTF-8): "
read -r lang
echo "$lang" > /etc/locale.conf

clear
echo "Choose keyboard layout in:"
echo "[Press enter to continue]"
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

echo "For nvidia drivers, see at https://wiki.archlinux.org/index.php/NVIDIA"

echo "Installing Xorg..."
pacman -S xorg
echo "Setting keyboard layout..."
echo "Enter layout (usually a 2-letter country code): "
read -r layout
localectl set-x11-keymap "$layout"

clear
echo "Setting power management (handled by systemd):"
echo "[Press enter to continue]"
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
useradd -m -s /bin/zsh "$user"

echo "Installing the i3 WM..."
pacman -S i3-gaps

echo "Installing basic applications..."
pacman -S compton lxappearance sxhkd dmenu i3-scrot i3status dunst ffmpeg python-pywal mpv feh yaourt neofetch neovim htop curl wget youtube-dl youtube-viewer betterlockscreen xdotool lemonbar-xft pass mupdf zathura
echo "Installing AUR apps..."
yaourt -S bmenu rofi-surfraw-git
echo "Installing additional apps..."
pacman -S mpd ncmpcpp mpc code firefox pcmanfm surf go nnn
yaourt -S google-chrome lf

clear
echo "Configuring your new system..."
su "$user" -c "zsh"
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

clear
echo "Do you want to continue with default configuration ? [Y/n]"
read -r conf
if [ "$conf" = "Y" ] || [ "$conf" = "y" ]; then
    exit 0
fi
cd /home/"$user" || exit 1
export HOME="/home/$user"
mkdir -p clones
sudo pacman -S git gcc make
git clone https://github.com/ghuter/scripts .scripts
cd clones || exit 1
git clone https://github.com/ghuter/st
cd st || exit 1
make && sudo make install
cd .. || exit 1
git clone https://github.com/ghuter/dotfiles
cd dotfiles || exit 1
cp .Xresources .bash_zsh_common .zshrc .mailcap .nanorc .urlview "$HOME"/
cp -r .config/htop .config/i3 .config/nvim .config/rofi .config/sxhkd .config/via .config/youtube-viewer .config/zathura .config/compton.conf .config/i3-scrot.conf "$HOME"/.config/
mkdir "$HOME"/.mozilla/firefox/*.default/chrome
cp .mozilla/firefox/*.default/chrome/userContent.css "$HOME"/.mozilla/firefox/*.default/chrome/


echo "Do you want to reboot now ? [Y/n]"
read -r rb
if [ "$rb" = "Y" ] || [ "$rb" = "y" ]; then
    reboot
fi

