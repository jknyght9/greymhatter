#!/bin/bash

USERNAME="$1"

echo -e "Installing Hayabusa"
CWD=$(pwd)
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

echo -e "Cleaning up"
rm -rf lib*
dnf groupremove "Development Tools" -y
dnf remove autoconf automake libtool maven -y

cd "$CWD"
