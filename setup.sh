#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
USERNAME='hatter'
PASSWORD='H@tt3r123!'
HOSTNAME='greymhatter'
CURRENT_DIR=$(pwd)
ARCH=$(uname -m)

if [ "$EUID" -ne 0 ]; then
  echo "Must be ran as root."
  exit 1 
fi 

echo -e "${GREEN}[+] Checking architecture${NC}"
if [[ "$ARCH" == "x86_64" ]]; then
    echo "Running on x86_64"
elif [[ "$ARCH" == "aarch64" ]]; then
    echo "Running on ARM64"
fi

clear
echo -e "${GREEN}[+] Optimizing and Updating Fedora${NC}"
echo 'fastestmirror=1' | tee -a /etc/dnf/dnf.conf
echo 'max_parallel_downloads=10' | tee -a /etc/dnf/dnf.conf
echo 'deltarpm=true' | tee -a /etc/dnf/dnf.conf
dnf clean all
#dnf upgrade --refresh -y
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
dnf install afflib alacritty bat btop conky curl fish dbus-x11 duf ewftools exa firefox gnome-shell-extension-apps-menu gnome-shell-extension-blur-my-shell gnome-shell-extension-dash-to-dock gnome-shell-extension-dash-to-panel gnome-shell-extension-caffeine gnome-shell-extension-user-theme gnome-terminal gnome-tweaks git neofetch neovim ntfs-3g openssl python3 python3-pip sassc tcpdump tmux unzip util-linux-user wget wireshark xorg-x11-server-utils -y --skip-unavailable

echo -e "${GREEN}[+] Installing CTOP${NC}"
if [[ "$ARCH" == "aarch64" ]]; then
  wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-arm64 -O /usr/local/bin/ctop
else
  wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
fi
chmod +x /usr/local/bin/ctop

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
docker --version
docker compose --version

echo -e "${GREEN}[+] Creating $USERNAME user${NC}"
ENC_PASSWORD=$(openssl passwd -6 $PASSWORD)
if id "$USERNAME" &>/dev/null; then 
  usermod -aG wheel,docker $USERNAME
  echo "$USERNAME exists"
else 
  useradd -m -G wheel,docker $USERNAME -p "$ENC_PASSWORD" -s $(which fish)
fi

echo -e "${YELLOW}[!] Please login as user '$USERNAME' in another terminal or TTY to complete the user session setup.${NC}"
echo -e "1. Open new Terminal or Terminal tab"
echo -e "2. Run 'su -l hatter'"
echo -e "3. Run 'xdg-user-dirs-update && xdg-open .'"
echo -e "4. Run 'exit' and close the Terminal or tab"
echo -e "${YELLOW}Once logged in, return here and press Enter to continue...${NC}"
read -p ""

echo -e "${GREEN}[+] Setting up user profile${NC}"
chsh -s $(which fish) $USERNAME
mkdir -p /home/$USERNAME/Pictures
cp $CURRENT_DIR/media/greymhatter-background.jpg /home/$USERNAME/Pictures/background.jpg
cp $CURRENT_DIR/media/greymhatter-logo.png /var/lib/AccountsService/icons/$USERNAME
cp -r $CURRENT_DIR/home/conky/conkyrc /home/$USERNAME/.conkyrc
cp -r $CURRENT_DIR/home/config/* /home/$USERNAME/.config
cp -r $CURRENT_DIR/home/local/* /home/$USERNAME/.local 
chmod +x /home/$USERNAME/.local/share/applications/dashboard.desktop
git clone https://github.com/tmux-plugins/tpm /home/$USERNAME/.config/tmux/plugins/tpm
chown -R $USERNAME:$USERNAME /home/$USERNAME
chmod +x /home/$USERNAME/.local/share/applications/dashboard.desktop
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

# Starting long installations in parallel
echo -e "${GREEN}[+] Installing Volatility3${NC}"
sudo gnome-terminal --working-directory="$CURRENT_DIR" -- bash -c "bash ./scripts/install-volatility3.sh $USERNAME; read -p \"Enter to continue\""

echo -e "${GREEN}[+] Installing DFIR Tools${NC}"
sudo gnome-terminal --working-directory="$CURRENT_DIR" -- bash -c "bash ./scripts/install-tools.sh $USERNAME; read -p \"Enter to continue\""

echo -e "${GREEN}[+] Installing Gnome and Terminal Themes${NC}"
sudo gnome-terminal --working-directory="$CURRENT_DIR" -- bash -c "bash ./scripts/install-environment.sh $USERNAME; read -p \"Enter to continue\""

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

echo -e "${GREEN}[+] Installing DFIQ${NC}"
bash ./scripts/install-dfiq.sh
if [[ $? -ne 0 ]]; then
  echo "DFIQ installation failed"
else
  echo "DFIQ installation completed"
fi

read -p "Enter to continue"
clear

# Install containers
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

# Do not resequence this section!
echo -e "${GREEN}[+] Setting up GNOME${NC}"
bash ./scripts/install-gnome-environment.sh "$USERNAME"
if [[ $? -ne 0 ]]; then
  echo "Gnome configuration failed"
else
  echo "Gnome configuration completed"
fi
