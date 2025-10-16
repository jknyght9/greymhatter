#!/bin/bash

USERNAME="$1"
CWD=$(pwd)

echo -e "Installing Eza (ls replacement)"
wget -q -O - https://github.com/eza-community/eza/releases/download/v0.23.4/eza_x86_64-unknown-linux-musl.tar.gz | tar zx
chown root:root eza
chmod 755 eza
mv eza /usr/local/bin

echo -e "Installing Hayabusa"
mkdir /opt/tools/
cd /opt/tools/
wget $(wget -q -O - https://api.github.com/repos/Yamato-Security/hayabusa/releases/latest | jq -r '.assets[] | select(.name | contains ("all-platforms")) | .browser_download_url')
unzip hayabusa*.zip -d hayabusa
cd hayabusa
mv hayabusa*-musl hayabusa
chmod +x hayabusa
./hayabusa update-rules
ln -s /opt/tools/hayabusa/hayabusa /home/$USERNAME/.local/bin/hayabusa
cd ..
rm hayabusa*.zip 

echo -e "Installing Malware Analysis Tools"
cd /opt/tools
wget $(wget -q -O - https://api.github.com/repos/mandiant/capa/releases/latest | jq -r '.assets[] | select(.name | contains ("linux.zip")) | .browser_download_url')
wget $(wget -q -O - https://api.github.com/repos/mandiant/flare-floss/releases/latest | jq -r '.assets[] | select(.name | contains ("linux")) | .browser_download_url')
wget $(wget -q -O - https://api.github.com/repos/VirusTotal/vt-cli/releases/latest | jq -r '.assets[] | select(.name | contains ("Linux64")) | .browser_download_url')
rm capa*-py311.zip 
unzip capa*.zip 
unzip floss*.zip
unzip Linux64.zip
ln -s /opt/tools/capa /home/$USERNAME/.local/bin/capa
ln -s /opt/tools/floss /home/$USERNAME/.local/bin/floss
ln -s /opt/tools/vt /home/$USERNAME/.local/bin/vt
rm capa*.zip floss*.zip Linux64.zip

echo -e "Installing Sleuthkit"
cd /opt/tools
wget $(wget -q -O - https://api.github.com/repos/sleuthkit/sleuthkit/releases/latest | jq -r '.assets[] | select(.name | contains ("tar.gz")) | .browser_download_url')
dnf groupinstall "Development Tools" -y
dnf install autoconf automake libtool maven zlib-devel e2fsprogs-devel libuuid-devel afflib-devel libewf-devel -y
tar zxf sleuthkit*.tar.gz
rm -f *.tar.gz*
cd sleuthkit*
./configure
make
make install
fls -V
cd ..
rm -rf sleuthkit*

echo -e "Installing Bulk Extractor"
cd /opt/tools
git clone --recurse-submodules https://github.com/simsong/bulk_extractor.git 
cd bulk_extractor
dnf install autoconf automake re2 re2-devel flex -y 
./bootstrap
./configure --disable-libewf 
make 
make install 
bulk_extractor -V

echo -e "Installing Encryption Tools"
cd /opt/tools
dnf install apfs-fuse cryptsetup dislocker exfatprogs foremost hashcat scalpel -y
wget https://launchpad.net/veracrypt/trunk/1.26.20/+download/veracrypt-1.26.20-Fedora-40-x86_64.rpm
rpm -i https://launchpad.net/veracrypt/trunk/1.26.20/+download/veracrypt-1.26.20-Fedora-40-x86_64.rpm

echo -e "Installing bdemount from source"
dnf install bison gcc gettext-devel libtool pkg-config fuse-devel zlib-devel python3-devel python3-setuptools -y 
ln -s /usr/bin/bison /usr/bin/yacc
git clone https://github.com/libyal/libbde.git
cd libbde
./synclibs.sh
./autogen.sh
./configure --enable-python
make
sudo make install
sudo ldconfig

echo -e "Installing fvdeemount from source"
git clone https://github.com/libyal/libfvde.git
cd libfvde
./synclibs.sh
./autogen.sh
./configure --enable-python
make
sudo make install
sudo ldconfig

echo -e "Cleaning up"
rm -rf lib*
dnf groupremove "Development Tools" -y
dnf remove autoconf automake libtool maven -y

cd "$CWD"
