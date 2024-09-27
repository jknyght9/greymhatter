#!/bin/bash

USERNAME="$1"
PASSWORD="$2"

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
echo -e "Enter password for SMB share."
set +H
echo "$PASSWORD\n$PASSWORD" | smbpasswd -s -a hatter
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

