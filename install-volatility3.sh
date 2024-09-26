#!/bin/bash

USERNAME="$1"

echo -e "Installing Volatility 3"
CWD=$(pwd)
cd /opt
dnf install gcc python3 python3-devel python3-pip -y
pip3 install wheel pefile pycryptodome
echo -e "Switching to ${USERNAME}"
su - $USERNAME << EOF
git clone --branch="stable" --recursive --single-branch https://github.com/volatilityfoundation/volatility3.git
git clone --branch="main" --recursive --single-branch https://github.com/JPCERTCC/Windows-Symbol-Tables.git symbols
git clone --branch="master" --recursive --single-branch https://github.com/VirusTotal/yara-python
curl --location --max-redirs 1 https://downloads.volatilityfoundation.org/volatility3/symbols/windows.zip --output windows.zip
curl --location --max-redirs 1 https://downloads.volatilityfoundation.org/volatility3/symbols/linux.zip --output linux.zip
curl --location --max-redirs 1 https://downloads.volatilityfoundation.org/volatility3/symbols/mac.zip --output mac.zip
curl --location --max-redirs 1 https://downloads.volatilityfoundation.org/volatility3/symbols/SHA256SUMS --output symbols.sha256
sha256sum -c symbols.sha256
echo -e "Installing Yara"
cd yara-python
pip3 install .
cd ..
echo -e "Installing Volatility 3"
cd volatility3
pip3 install .
cd ..
export PATH="$HOME/.local/bin:$PATH"
cp *.zip $HOME/.local/lib/python3.12/site-packages/volatility3/symbols/
cp -r symbols/symbols/windows/ $HOME/.local/lib/python3.12/site-packages/volatility3/symbols/windows
echo -e "Downloading malware sample and caching symbol tables, this will take a while"
curl -O https://cc-public.s3.amazonaws.com/0zapftis.zip
unzip -P infected 0zapftis.zip
vol -vvv -f 0zapftis.vmem windows.info
rm -rf 0zapftis* linux.zip mac.zip symbols/ symbols.sha256 volatility3/ windows.zip yara-python/
EOF
echo -e "Switching to back to root"
cd "$CWD"
