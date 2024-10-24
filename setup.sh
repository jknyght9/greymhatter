#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m' # No Color
USERNAME='hatter'
PASSWORD='H@tt3r123!'
HOSTNAME='greymhatter'
CURRENT_DIR=$(pwd)

if [ "$EUID" -ne 0 ]; then
  echo "Must be ran as root."
  exit 1 
fi 

clear
echo -e "${GREEN}[+] Optimizing and Updating Fedora${NC}"
echo 'fastestmirror=1' | tee -a /etc/dnf/dnf.conf
echo 'max_parallel_downloads=10' | tee -a /etc/dnf/dnf.conf
echo 'deltarpm=true' | tee -a /etc/dnf/dnf.conf
dnf clean all
dnf upgrade --refresh -y
dnf check
dnf autoremove -y
fwupdmgr get-devices
fwupdmgr refresh --force
fwupdmgr get-updates
fwupdmgr update -y

echo -e "${GREEN}[+] Setting SELinux to permissive${NC}"
sed -i 's/=enforcing/=permissive/g' /etc/selinux/config

echo -e "${GREEN}[+] Setting system hostname${NC}"
hostnamectl set-hostname "${HOSTNAME}"
echo "${HOSTNAME}.jdclabs.io ${HOSTNAME}" > /etc/hosts
echo "127.0.0.1 ${HOSTNAME}.jdclabs.io ${HOSTNAME}" >> /etc/hosts
cat >> /etc/hosts <<EOF
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

echo -e "${GREEN}[+] Installing required software${NC}"
dnf install afflib bat btop conky curl fish duf ewftools exa gnome-shell-extension-apps-menu gnome-shell-extension-blur-my-shell gnome-shell-extension-dash-to-dock gnome-shell-extension-dash-to-panel gnome-shell-extension-caffeine gnome-shell-extension-user-theme gnome-tweaks git neofetch neovim ntfs-3g openssl python3 python3-pip sassc tmux util-linux-user wget -y

echo -e "${GREEN}[+] Installing CTOP${NC}"
wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
chmod +x /usr/local/bin/ctop

echo -e "${GREEN}[+] Installing Hack Nerd Fonts${NC}"
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip\
	&& unzip Hack.zip -d /usr/share/fonts/ \
	&& fc-cache -fv \
	&& rm -rf Hack*

echo -e "${GREEN}[+] Installing Colloid theme${NC}"
mkdir theme
cd theme
wget -O colloid-icons.zip https://github.com/vinceliuice/Colloid-icon-theme/archive/refs/tags/2024-10-18.zip
wget -O colloid-theme.zip https://github.com/vinceliuice/Colloid-gtk-theme/archive/refs/tags/2024-06-18.zip
unzip colloid-icons.zip -d colloid-icons
unzip colloid-theme.zip -d colloid-theme
cd colloid-icons/Colloid* 
./install.sh -s nord
cd ../../colloid-theme/Colloid*
./install.sh
cd ../../..
rm -rf theme

echo -e "${GREEN}[+] Installing Starship${NC}"
curl -O https://starship.rs/install.sh \
	&& sh ./install.sh -f \
	&& rm -f install.sh

echo -e "${GREEN}[+] Installing Docker${NC}"
curl -fsSL https://get.docker.com -o get-docker.sh
chmod u+x ./get-docker.sh
sh ./get-docker.sh
systemctl enable --now docker 
systemctl start docker 
rm get-docker.sh

echo -e "${GREEN}[+] Creating $USERNAME user${NC}"
ENC_PASSWORD=$(openssl passwd -6 $PASSWORD)
if id "$USERNAME" &>/dev/null; then 
  usermod -aG wheel,docker $USERNAME
  echo "$USERNAME exists"
else 
  useradd -m -G wheel,docker $USERNAME -p "$ENC_PASSWORD" -s $(which fish)
fi

echo -e "${GREEN}[+] Setting up user profile${NC}"
chsh -s $(which fish) $USERNAME
cp $CURRENT_DIR/media/greymhatter-background.jpg /home/$USERNAME/Pictures/background.jpg
chown $USERNAME:$USERNAME /home/$USERNAME/Pictures/background.jpg
cp $CURRENT_DIR/media/greymhatter-logo.png /var/lib/AccountsService/icons/$USERNAME
cp -r $CURRENT_DIR/home/conky/conkyrc /home/$USERNAME/.conkyrc
chown -R $USERNAME:$USERNAME /home/$USERNAME/.conkyrc
cp -r $CURRENT_DIR/home/config/* /home/$USERNAME/.config
chown -R $USERNAME:$USERNAME /home/$USERNAME/.config
cp -r $CURRENT_DIR/home/local/* /home/$USERNAME/.local 
chown -R $USERNAME:$USERNAME /home/$USERNAME/.local
chmod +x /home/$USERNAME/.local/share/applications/dashboard.desktop
git clone https://github.com/tmux-plugins/tpm /home/$USERNAME/.config/tmux/plugins/tpm
chown -R $USERNAME:$USERNAME /home/$USERNAME/.config/tmux
runuser -l $USERNAME -c 'bash -s' << 'EOF'
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
systemctl --user daemon-reload
systemctl --user enable conky.service
systemctl --user start conky.service
EOF

echo -e "${GREEN}[+] Setting up EWF mount points${NC}"
mkdir -p /mnt/{ewf,windows_mount}
chgrp -R $USERNAME /mnt/*
chmod -R 777 /mnt/*

read -p "Enter to continue"
clear

# Starting long installations first
echo -e "${GREEN}[+] Installing Volatility3${NC}"
sudo gnome-terminal --working-directory="$CURRENT_DIR" -- bash -c "bash ./scripts/install-volatility3.sh $USERNAME; read -p \"Enter to continue\""

echo -e "${GREEN}[+] Installing DFIR Tools${NC}"
sudo gnome-terminal --working-directory="$CURRENT_DIR" -- bash -c "./scripts/install-tools.sh $USERNAME; read -p \"Enter to continue\""

echo -e "${GREEN}[+] Installing DFIQ${NC}"
bash ./scripts/install-dfiq.sh
if [[ $? -ne 0 ]]; then
  echo "DFIQ installation failed"
else
  echo "DFIQ installation completed"
fi

read -p "Enter to continue"
clear

echo -e "${GREEN}[+] Installing Maxmind${NC}"
bash ./scripts/install-maxmind.sh
if [[ $? -ne 0 ]]; then
  echo "Maxmind installation failed"
else
  echo "Maxmind installation completed"
fi

read -p "Enter to continue"
clear

echo -e "${GREEN}[+] Installing Timesketch${NC}"
bash ./scripts/install-timesketch.sh "$CURRENT_DIR" "$USERNAME" "$PASSWORD"
if [[ $? -ne 0 ]]; then
  echo "Timesketch installation failed"
else
  echo "Timesketch installation completed"
fi

read -p "Enter to continue"
clear

echo -e "${GREEN}[+] Installing Yeti${NC}"
bash ./scripts/install-yeti.sh "$USERNAME" "$PASSWORD"
if [[ $? -ne 0 ]]; then
  echo "Yeti installation failed"
else
  echo "Yeti installation completed"
fi

read -p "Enter to continue"
clear

echo -e "${GREEN}[+] Installing Spiderfoot${NC}"
bash ./scripts/install-spiderfoot.sh "$CURRENT_DIR"
if [[ $? -ne 0 ]]; then
  echo "Spiderfoot installation failed"
else
  echo "Spiderfoot installation completed"
fi

read -p "Enter to continue"
clear

echo -e "${GREEN}[+] Installing Volatility2${NC}"
bash ./scripts/install-volatility2.sh "$USERNAME"
if [[ $? -ne 0 ]]; then
  echo "Volatility 2 installation failed"
else 
  echo "Volatility 2 installation completed"
fi 

read -p "Enter to continue"
clear

echo -e "${GREEN}[+] Installing Powershell${NC}"
bash ./scripts/install-pwsh.sh
if [[ $? -ne 0 ]]; then
  echo "Powershell installation failed"
else 
  echo "Powershell installation completed"
fi 

read -p "Enter to continue"
clear

echo -e "${GREEN}[+] Installing Samba${NC}"
bash ./scripts/install-smbshare.sh "$USERNAME" "$PASSWORD"
if [[ $? -ne 0 ]]; then
  echo "Samba share installation failed"
else 
  echo "Samba share installation completed"
fi

read -p "Enter to continue"
clear

echo -e "${GREEN}[+] Installing Cyberchef${NC}"
bash ./scripts/install-cyberchef.sh "$CURRENT_DIR"
if [[ $? -ne 0 ]]; then
  echo "Cyberchef installation failed"
else 
  echo "Cyberchef installation completed"
fi 

read -p "Enter to continue"
clear

echo -e "${GREEN}[+] Installing Homepage - Dashboard${NC}"
bash ./scripts/install-homepage.sh "$CURRENT_DIR"
if [[ $? -ne 0 ]]; then
  echo "Homepage installation failed"
else
  echo "Homepage installation completed"
fi

read -p "Enter to continue"
clear

echo -e "${GREEN}[+] Setting up GNOME${NC}"
bash ./scripts/install-gnome-environment.sh "$USERNAME"
if [[ $? -ne 0 ]]; then
  echo "Gnome configuration failed"
else
  echo "Gnome configuration completed"
fi
