#!/bin/sh

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
echo "Tap in your choice:"
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
pacman -S zsh bash dash bash-completion
echo "Symlink /bin/sh to dash"
ln -s /bin/sh /usr/bin/dash

echo "New user name: "
read -r user
useradd -m -s /bin/zsh "$user"
passwd "$user"

echo "Installing the i3 WM..."
pacman -S i3-gaps

echo "Installing basic applications..."
pacman -S compton lxappearance sxhkd dmenu i3-scrot i3status dunst ffmpeg python-pywal mpv feh yaourt neofetch neovim htop curl wget youtube-dl youtube-viewer betterlockscreen xdotool lemonbar-xft pass mupdf zathura
echo "Installing AUR apps..."
yaourt -S bmenu rofi-surfraw-git
echo "Installing additional apps..."
pacman -S mpd ncmpcpp mpc code firefox pcmanfm surf go nnn
yaourt -S google-chrome lf

