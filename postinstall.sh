#!/bin/sh

cd "$HOME" || exit 1

sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

sudo pacman -S git gcc make
git clone https://github.com/ghuter/scripts .scripts

mkdir -p clones

cd clones || exit 1
git clone https://github.com/ghuter/st
cd st || exit 1
make && sudo make install
cd .. || exit 1

git clone https://github.com/ghuter/dotfiles
cd dotfiles || exit 1
cp .Xresources .bash_zsh_common .zshrc .mailcap .nanorc .urlview "$HOME"/
cp -r .config/htop .config/i3 .config/nvim .config/rofi .config/sxhkd .config/via .config/youtube-viewer .config/zathura .config/compton.conf .config/i3-scrot.conf "$HOME"/.config/
mkdir -p "$HOME"/.mozilla/firefox/*.default/chrome
cp .mozilla/firefox/*.default/chrome/userContent.css "$HOME"/.mozilla/firefox/*.default/chrome/

