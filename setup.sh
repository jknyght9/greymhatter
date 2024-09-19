#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m' # No Color
USERNAME='hatter'
PASSWORD='H@tt3r123!'

function colorize() {
	printf "$2$1$NC$3"
}

if [ "$EUID" -ne 0 ]; then
  echo "Must be ran as root."
  exit 1 
fi 

colorize "[+]" $GREEN " Optimizing and Updating Fedora"
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

colorize "[+]" $GREEN " Setting SELinux to permissive"
sed -i 's/=enforcing/=permissive/g' /etc/selinux/config

colorize "[+]" $GREEN " Installing required software"
dnf install bat btop curl fish duf exa git neovim tmux util-linux-user wget -y

colorize "[+]" $GREEN " Installing Hack Nerd Fonts"
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip\
	&& unzip Hack.zip -d ~/.fonts \
	&& fc-cache -fv \
	&& rm -rf Hack*

colorize "[+]" $GREEN " Installing Starship"
curl -O https://starship.rs/install.sh \
	&& sh ./install.sh -f \
	&& rm -f install.sh

colorize "[+]" $GREEN " Installing Podman"
dnf install podman cockpit-podman podman-compose -y
systemctl enable podman --now

colorize "[+]" $GREEN " Setting up user"
useradd -m -G wheel $USERNAME -p $PASSWORD -s $(which fish)

su - $USERNAME << EOF
whoami
cp ./config/starship.toml ~/.config
mkdir -p ~/.config/fish
cp ./config/fish/config.fish ~/.config/fish
mkdir -p ~/.config/tmux 
cp ./config/tmux/tmux.conf ~/.config/tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && chown -R 1000:1000 ~/.tmux
mkdir -p ~/.config/nvim 
cp -R ./config/nvim/* ~/.config/nvim/
EOF

whoami

colorize "[+]" $GREEN " Installing Samba (Windows Share)"
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


