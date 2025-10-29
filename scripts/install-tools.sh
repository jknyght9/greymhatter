#!/bin/bash

USERNAME="$1"
ARCH="$2"
CWD=$(pwd)

# Colors for terminal outputs
C_RESET="\033[0m"
C_YELLOW="\033[1;33m"
C_BLUE="\033[0;34m"

# Functions for convenience
function doing()        { echo -e "${C_BLUE}[>] $*${C_RESET}"; }
function question()     { echo -e "  ${C_YELLOW}[?] $*${C_RESET}"; }
function pressAnyKey()  { read -n 1 -s -p "$(question "Press any key to continue")"; echo; }

doing "Installing Powershell"
rpm --import https://packages.microsoft.com/keys/microsoft.asc
curl https://packages.microsoft.com/config/rhel/7/prod.repo | tee /etc/yum.repos.d/microsoft.repo
dnf makecache -y
dnf install powershell -y
pressAnyKey

doing "Installing Hayabusa"
mkdir /opt/tools/
cd /opt/tools/
wget $(wget -q -O - https://api.github.com/repos/Yamato-Security/hayabusa/releases/latest | jq -r '.assets[] | select(.name | contains ("all-platforms")) | .browser_download_url')
unzip -q hayabusa*.zip -d hayabusa
cd hayabusa

if [[ "$ARCH" == "x86_64" ]]; then
  mv hayabusa*-musl hayabusa
elif [[ "$ARCH" == "aarch64" ]]; then
  find . -name "$ARCH-gnu" -exec mv {} hayabusa \;
fi

chmod +x hayabusa
./hayabusa update-rules
ln -s /opt/tools/hayabusa/hayabusa /home/$USERNAME/.local/bin/hayabusa
cd ..
rm hayabusa*.zip 
pressAnyKey

if [[ "$ARCH" == "x86_64" ]]; then
  doing "Installing Malware Analysis Tools"
  cd /opt/tools
  wget $(wget -q -O - https://api.github.com/repos/mandiant/capa/releases/latest | jq -r '.assets[] | select(.name | contains ("linux.zip")) | .browser_download_url')
  wget $(wget -q -O - https://api.github.com/repos/mandiant/flare-floss/releases/latest | jq -r '.assets[] | select(.name | contains ("linux")) | .browser_download_url')
  wget $(wget -q -O - https://api.github.com/repos/VirusTotal/vt-cli/releases/latest | jq -r '.assets[] | select(.name | contains ("Linux64")) | .browser_download_url')
  rm capa*-py311.zip 
  unzip -q capa*.zip 
  unzip -q floss*.zip
  unzip -q Linux64.zip
  ln -s /opt/tools/capa /home/$USERNAME/.local/bin/capa
  ln -s /opt/tools/floss /home/$USERNAME/.local/bin/floss
  ln -s /opt/tools/vt /home/$USERNAME/.local/bin/vt
  rm capa*.zip floss*.zip Linux64.zip
  pressAnyKey
fi

doing "Installing Sleuthkit"
if [[ "$ARCH" == "x86_64" ]]; then
  cd /opt/tools
  wget $(wget -q -O - https://api.github.com/repos/sleuthkit/sleuthkit/releases/latest | jq -r '.assets[] | select(.name | contains ("tar.gz")) | .browser_download_url')
  dnf groupinstall "Development Tools" -y
  dnf install autoconf automake gcc gcc-c++ libtool maven zlib-devel e2fsprogs-devel libuuid-devel afflib-devel libewf-devel libvmdk-devel libvhdi-devel libvhdx-devel libuuid-devel -y
  tar zxf sleuthkit*.tar.gz
  rm -f *.tar.gz*
  cd sleuthkit*
  ./configure
  make
  make install
  fls -V
  cd ..
  rm -rf sleuthkit*
elif [[ "$ARCH" == "aarch64" ]]; then
  dnf install sleuthkit -y
  fls -V
fi
pressAnyKey

if [[ "$ARCH" == "x86_64" ]]; then
  doing "Installing Bulk Extractor"
  cd /opt/tools
  git clone --recurse-submodules https://github.com/simsong/bulk_extractor.git 
  cd bulk_extractor
  dnf install autoconf automake re2 re2-devel flex -y 
  ./bootstrap
  ./configure --disable-libewf 
  make 
  make install 
  bulk_extractor -V
  pressAnyKey
fi

doing "Installing Encryption Tools"
cd /opt/tools
dnf install apfs-fuse cryptsetup dislocker exfatprogs foremost hashcat scalpel -y
# Install veracrypt
dnf install dnf-plugins-core
dnf copr enable architektapx/veracrypt
dnf install veracrypt
veracrypt --version

# wget https://launchpad.net/veracrypt/trunk/1.26.20/+download/veracrypt-1.26.20-Fedora-40-x86_64.rpm
# rpm -i https://launchpad.net/veracrypt/trunk/1.26.20/+download/veracrypt-1.26.20-Fedora-40-x86_64.rpm
pressAnyKey

doing "Installing bdemount from source"
dnf install bison gcc gettext-devel libtool pkg-config fuse-devel zlib-devel python3-devel python3-setuptools -y 
ln -s /usr/bin/bison /usr/bin/yacc
git clone https://github.com/libyal/libbde.git
cd libbde
./synclibs.sh
./autogen.sh
./configure --enable-python
make
make install
ldconfig
pressAnyKey

doing "Installing fvdeemount from source"
git clone https://github.com/libyal/libfvde.git
cd libfvde
./synclibs.sh
./autogen.sh
./configure --enable-python
make
make install
ldconfig
pressAnyKey

doing "Cleaning up"
rm -rf lib*
dnf groupremove "Development Tools" -y
dnf remove autoconf automake libtool maven -y

cd "$CWD"
