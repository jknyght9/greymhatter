#!/bin/bash

echo -e "Installing Hayabusa"
CWD=$(pwd)
mkdir /opt/tools/
cd /opt/tools/
wget $(wget -q -O - https://api.github.com/repos/Yamato-Security/hayabusa/releases/latest | jq -r '.assets[] | select(.name | contains ("linux-intel")) | .browser_download_url')
unzip hayabusa*.zip -d hayabusa
cd hayabusa
mv hayabusa*-musl hayabusa
chmod +x hayabusa
./hayabusa update-rules
cd ..
rm hayabusa*.zip 

echo -e "Installing Malware Analysis Tools"
cd /opt/tools
wget $(wget -q -O - https://api.github.com/repos/mandiant/capa/releases/latest | jq -r '.assets[] | select(.name | contains ("linux.zip")) | .browser_download_url')
wget $(wget -q -O - https://api.github.com/repos/mandiant/flare-floss/releases/latest | jq -r '.assets[] | select(.name | contains ("linux")) | .browser_download_url')
rm capa*-py311.zip 
unzip capa*.zip 
unzip floss*.zip
rm capa*.zip floss*.zip

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
dnf groupremove "Development Tools" -y
dnf remove autoconf automake libtool maven zlib-devel e2fsprogs-devel libuuid-devel afflib-devel libewf-devel -y
rm -rf sleuthkit*
cd "$CWD"
