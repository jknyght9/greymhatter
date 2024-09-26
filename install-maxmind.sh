#!/bin/bash

echo -e "Installing Maxmind GeoIP Database"
CWD=$(pwd)
cd /opt/ 
git clone https://github.com/jknyght9/maxmind-geoipupdate.git --depth 1 maxmind-geoipupdate 
read -p "Enter your Maxmind Account ID: " ACCOUNTID
read -p "Enter your License Key: " LICENSEKEY
if [[ -n "$ACCOUNTID" && -n "$LICENSEKEY" ]]; then
  echo "GEOIPUPDATE_ACCOUNT_ID=$ACCOUNTID" > /opt/maxmind-geoipupdate/.env
  echo "GEOIPUPDATE_LICENSE_KEY=$LICENSEKEY" >> /opt/maxmind-geoipupdate/.env
  echo -e "Configuring Maxmind for Timesketch"
  sed -i "s/MAXMIND_DB_PATH = ''/MAXMIND_DB_PATH = '\/opt\/maxmind\/GeoLite2-City.mmdb'/g" /opt/timesketch/etc/timesketch/timesketch.conf
  docker compose up -d
  if [[ "$(docker inspect -f '{{.State.Running}}' geoipupdate)" == "true"]]; then
    if [[ "$(docker inspect -f '{{.State.Running}}' timesketch-worker)" == "true" ]]; then
      echo "Restarting Timesketch worker"
      docker compose restart timesketch-worker
    fi
    echo "Maxmind updater is running"
  else
    echo "Maxmind updater is not running"
  fi
else 
  echo "No account ID or license key, aborting."
fi 
cd "$CWD"
