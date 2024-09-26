#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m' # No Color
USERNAME='hatter'
PASSWORD='H@tt3r123!'
ENC_PASSWORD=$(openssl passwd -6 $PASSWORD)
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
dnf autoremove
fwupdmgr get-devices
fwupdmgr refresh --force
fwupdmgr get-updates
fwupdmgr update -y

echo -e "${GREEN}[+] Setting SELinux to permissive${NC}"
sed -i 's/=enforcing/=permissive/g' /etc/selinux/config

echo -e "${GREEN}[+] Installing required software${NC}"
dnf install bat btop curl fish duf exa git neovim python3 python3-pip tmux util-linux-user wget -y

echo -e "${GREEN}[+] Installing Hack Nerd Fonts${NC}"
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip\
	&& unzip Hack.zip -d ~/.fonts \
	&& fc-cache -fv \
	&& rm -rf Hack*

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

echo -e "${GREEN}[+] Setting up user${NC}"
if id "$USERNAME" &>/dev/null; then 
  echo "$USERNAME exists"
else 
  useradd -m -G wheel $USERNAME -p "$ENC_PASSWORD" -s $(which fish)
fi

echo -e "${GREEN}[+] Switching to ${USERNAME}${NC}"
su - $USERNAME << EOF
cp -r $CURRENT_DIR/config/* ~/.config
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && chown -R 1000:1000 ~/.tmux
EOF
echo -e "${GREEN}[+] Switching to $(whoami)${NC}"

bash ./install-timesketch.sh "$CURRENT_DIR" "$USERNAME" "$PASSWORD"
if [[ $? -ne 0 ]]; then
  echo "Timesketch installation failed"
else
  echo "Timesketch installation completed"
fi

read -p "Enter to continue"

bash ./install-maxmind.sh
if [[ $? -ne 0 ]]; then
  echo "Maxmind installation failed"
else
  echo "Maxmind installation completed"
fi

read -p "Enter to continue"

bash ./install-yeti.sh "$USERNAME" "$PASSWORD"
if [[ $? -ne 0 ]]; then
  echo "Yeti installation failed"
else
  echo "Yeti installation completed"
fi

read -p "Enter to continue"

bash ./install-spiderfoot.sh "$CURRENT_DIR"
if [[ $? -ne 0 ]]; then
  echo "Spiderfoot installation failed"
else
  echo "Spiderfoot installation completed"
fi

read -p "Enter to continue"

bash ./install-volatility.sh "$USERNAME"
if [[ $? -ne 0 ]]; then
  echo "Volatility installation failed"
else 
  echo "Volatility installation completed"
fi 

read -p "Enter to continue"

bash ./install-tools.sh "$USERNAME"
if [[ $? -ne 0 ]]; then
  echo "DFIR tools installation failed"
else 
  echo "DFIR tools installation completed"
fi 

read -p "Enter to continue"

bash ./install-smbshare.sh "$USERNAME"
if [[ $? -ne 0 ]]; then
  echo "Samba share installation failed"
else 
  echo "Samba share installation completed"
fi

read -p "Enter to continue"

bash ./install-cyberchef.sh "$CURRENT_DIR"
if [[ $? -ne 0 ]]; then
  echo "Cyberchef installation failed"
else 
  echo "Cyberchef installation completed"
fi
