#!/bin/bash

CURRENT_DIR="$1"
USERNAME="$2"
PASSWORD="$3"
CWD=$(pwd)

# Colors for terminal outputs
C_RESET="\033[0m"
C_RED="\033[0;31m"
C_BLUE="\033[0;34m"

# Functions for convenience
function doing()        { echo -e "${C_BLUE}[>] $*${C_RESET}"; }
function error()        { echo -e "${C_RED}[X] $*${C_RESET}"; }

cd /opt
curl -s -O https://raw.githubusercontent.com/google/timesketch/master/contrib/deploy_timesketch.sh
chmod 755 deploy_timesketch.sh
bash ./deploy_timesketch.sh
if [[ $? -eq 0 ]]; then
  doing "Copying required files"
  cp $CURRENT_DIR/docker/timesketch/docker-compose.override.yml /opt/timesketch/
  cp $CURRENT_DIR/docker/timesketch/nginx.conf /opt/timesketch/etc
  cp $CURRENT_DIR/docker/timesketch/*.yaml /opt/timesketch/etc/timesketch
  cp $CURRENT_DIR/docker/timesketch/timesketchrc /home/$USERNAME/.timesketchrc
  chown $USERNAME:$USERNAME /home/$USERNAME/.timesketchrc

  doing "Configuring Maxmind for Timesketch"
  sed -i "s/MAXMIND_DB_PATH = ''/MAXMIND_DB_PATH = '\/opt\/maxmind\/GeoLite2-City.mmdb'/g" /opt/timesketch/etc/timesketch/timesketch.conf
  doing "Configuring SSL for Timesketch"
  mkdir -p /opt/timesketch/{ssl/certs,ssl/private}
  openssl req -x509 -out /opt/timesketch/ssl/certs/localhost.crt -keyout /opt/timesketch/ssl/private/localhost.key -newkey rsa:2048 -nodes -sha256 -subj '/CN=localhost' -extensions EXT -config <(printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
  chmod 600 /opt/timesketch/ssl/private/localhost.key 
  
  # Setup Maxmind
  if [[ "$(docker inspect -f '{{.State.Running}}' geoipupdate)" == "true" ]]; then
    doing "Configuring Timesketch with Maxmind"
    sed -i "s/MAXMIND_DB_PATH = ''/MAXMIND_DB_PATH = '\/opt\/maxmind\/GeoLite2-City.mmdb'/g" /opt/timesketch/etc/timesketch/timesketch.conf
  fi

  # Setup DFIQ
  if [[ -d "/opt/dfiq" ]]; then
    doing "Configuring Timesketch with DFIQ"
    sed -i 's/DFIQ_ENABLED = False/DFIQ_ENABLED = True/g' /opt/timesketch/etc/timesketch/timesketch.conf
  fi

  doing "Starting Timesketch"
  cd /opt/timesketch
  docker compose up -d
  #docker compose up --profile v3-ui -d

  # Wait till the web container is up
  while [ "$(docker inspect -f '{{.State.Running}}' timesketch-web 2>/dev/null)" != "true" ]; do
    sleep 10
  done

  # Create user
  doing "Creating Timesketch User"
  docker compose up -d
  docker compose exec timesketch-web tsctl create-user $USERNAME --password $PASSWORD
  
  doing "Installing Timesketch Importer"
  pip3 install timesketch-import-client
  rm /opt/deploy_timesketch.sh
else
  error "An error occurred while installing Timesketch"
fi

cd "$CWD"
