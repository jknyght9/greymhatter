#!/bin/bash

USERNAME="$1"

CWD=$(pwd)
echo -e "Switching to $USERNAME"
xhost +SI:localuser:$USERNAME
runuser -l $USERNAME -c 'bash -s' << 'EOF'
export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=$(dbus-launch | grep -Po '(?<=DBUS_SESSION_BUS_ADDRESS=)[^\n]+')
export XDG_RUNTIME_DIR=/run/user/$(id -u)

# Setup Gnome desktop
gsettings set org.gnome.desktop.interface clock-format '24h'
gsettings set org.gnome.desktop.interface clock-show-seconds true
gsettings set org.gnome.desktop.background picture-uri 'file:///home/hatter/Pictures/background.jpg'
gsettings set org.gnome.desktop.background picture-uri-dark 'file:///home/hatter/Pictures/background.jpg'
gsettings set org.gnome.desktop.background picture-options 'zoom'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.desktop.interface monospace-font-name 'Hack Nerd Font 10'
gsettings set org.gnome.shell favorite-apps "['dashboard.desktop', 'org.mozilla.firefox.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Settings.desktop']"

# Configuring power settings
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false

# Installing required gnome extensions
wget -O desktop-icons-ng.zip https://extensions.gnome.org/extension-data/dingrastersoft.com.v67.shell-extension.zip
wget -O logo-menu.zip https://extensions.gnome.org/extension-data/logomenuaryan_k.v35.shell-extension.zip
gnome-extensions install desktop-icons-ng.zip
gnome-extensions install logo-menu.zip

# Enabling extensions
gnome-extensions enable apps-menu@gnome-shell-extensions.gcampax.github.com
gnome-extensions enable blur-my-shell@aunetx
gnome-extensions enable caffeine@patapon.info
gnome-extensions enable dash-to-dock@micxgx.gmail.com
gnome-extensions enable ding@rastersoft.com
gnome-extensions enable logomenu@aryan_k
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com

EOF
xhost -SI:localuser:$USERNAME
echo -e "Switching to $(whoami)"
cd "$CWD"
