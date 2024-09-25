#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m' # No Color
CURRENT_DIR="$1"

echo -e "${GREEN}[+] Installing Timesketch${NC}"
CWD=$(pwd)
cd /opt
curl -s -O https://raw.githubusercontent.com/google/timesketch/master/contrib/deploy_timesketch.sh
chmod 755 deploy_timesketch.sh
./deploy_timesketch
if [[ $? -eq 0 ]]; then
  echo -e "${GREEN}[-] Copying required files${NC}"
  cp $CURRENT_DIR/timesketch/docker-compose.override.yml /opt/timesketch/
  cp $CURRENT_DIR/timesketch/nginx.conf /opt/timesketch/etc
  cp $CURRENT_DIR/timesketch/*.yaml /opt/timesketch/etc/timesketch
  echo -e "${GREEN}[-] Configuring Maxmind for Timesketch${NC}"
  sed -i "s/MAXMIND_DB_PATH = ''/MAXMIND_DB_PATH = '\/opt\/maxmind\/GeoLite2-City.mmdb'/g" /opt/timesketch/etc/timesketch/timesketch.conf
  echo -e "${GREEN}[-] Configuring SSL for Timesketch${NC}"
  mkdir -p /opt/timesketch/{ssl/certs,ssl/private}
  openssl req -x509 -out /opt/timesketch/ssl/certs/localhost.crt -keyout /opt/timesketch/ssl/private/localhost.key -newkey rsa:2048 -nodes -sha256 -subj '/CN=localhost' -extensions EXT -config <(printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
  chmod 600 /opt/timesketch/ssl/private/localhost.key 
else
  echo -e "${GREEN}[!] An error occured while installing Timesketch${NC}"
fi
