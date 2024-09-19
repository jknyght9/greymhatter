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
dnf install bat btop curl fish duf exa git neovim tmux util-linux-user wget -y

echo -e "${GREEN}[+] Installing Hack Nerd Fonts${NC}"
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip\
	&& unzip Hack.zip -d ~/.fonts \
	&& fc-cache -fv \
	&& rm -rf Hack*

echo -e "${GREEN}[+] Installing Starship${NC}"
curl -O https://starship.rs/install.sh \
	&& sh ./install.sh -f \
	&& rm -f install.sh

echo -e "${GREEN}[+] Installing Podman${NC}"
dnf install podman cockpit-podman podman-compose -y
systemctl enable podman --now

echo -e "${GREEN}[+] Setting up user${NC}"
useradd -m -G wheel $USERNAME -p "$ENC_PASSWORD" -s $(which fish)

echo -e "${GREEN}[+] Switching to ${USERNAME}${NC}"
su - $USERNAME << EOF
whoami
cp -r $CURRENT_DIR/config/* ~/.config
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && chown -R 1000:1000 ~/.tmux
EOF

echo -e "${GREEN}[+] Switching to ${USERNAME}${NC}"
whoami

echo -e "${GREEN}[+] Installing Samba (Windows Share)${NC}"
mkdir /opt/share
chown $USERNAME:$USERNAME /opt/share
dnf install samba -y
systemctl enable smb --now
firewall-cmd --permanent --zone=FedoraServer --add-service=samba
firewall-cmd --reload
groupadd samba
usermod -aG samba $USERNAME
chgrp samba /opt/share 
chmod 770 /opt/share 
semanage fcontext --add --type "samba_share_t" "/opt/share(/.*)?"
restorecon -R /opt/share
smbpasswd -a $USERNAME
cat <<EOF > /etc/samba/smb.conf
[share]
	comment = Share for evidence
	path = /opt/share
	writable = yes
	browseable = yes
	public = yes
	valid users = @samba
	create mask = 0660
	directory mask = 0770
	force group = +samba
EOF
systemctl restart smb


