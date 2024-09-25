#!/bin/bash

echo -e "${GREEN}[+] Installing Hayabusa${NC}"
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

echo -e "${GREEN}[+] Installing Malware Analysis Tools${NC}"
cd /opt/tools
wget $(wget -q -O - https://api.github.com/repos/mandiant/capa/releases/latest | jq -r '.assets[] | select(.name | contains ("linux.zip")) | .browser_download_url')
wget $(wget -q -O - https://api.github.com/repos/mandiant/flare-floss/releases/latest | jq -r '.assets[] | select(.name | contains ("linux")) | .browser_download_url')
rm capa*-py311.zip 
unzip capa*.zip 
unzip floss*.zip
rm capa*.zip floss*.zip

echo -e "${GREEN}[+] Installing Sleuthkit${NC}"
cd /opt/tools
wget $(wget -q -O - https://api.github.com/repos/sleuthkit/sleuthkit/releases/latest | jq -r '.assets[] | select(.name | contains ("tar.gz")) | .browser_download_url')
tar zxf sleuthkit*.tar.gz
# need to finish Installing
rm sleuthkit*.tar.gz*
