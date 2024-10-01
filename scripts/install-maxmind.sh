#!/bin/bash

CWD=$(pwd)
cd /opt/ 
git clone https://github.com/jknyght9/maxmind-geoipupdate.git --depth 1 
read -p "Enter your Maxmind Account ID: " ACCOUNTID
read -p "Enter your License Key: " LICENSEKEY
if [[ -n "$ACCOUNTID" && -n "$LICENSEKEY" ]]; then
  echo "GEOIPUPDATE_ACCOUNT_ID=$ACCOUNTID" > /opt/maxmind-geoipupdate/.env
  echo "GEOIPUPDATE_LICENSE_KEY=$LICENSEKEY" >> /opt/maxmind-geoipupdate/.env
  cd /opt/maxmind-geoipupdate
  docker compose up -d
  if [[ "$(docker inspect -f '{{.State.Running}}' geoipupdate)" == "true" ]]; then
    echo "Maxmind updater is running"
  else
    echo "Maxmind updater is not running"
  fi
else 
  echo "No account ID or license key, aborting."
fi 
cd "$CWD"
