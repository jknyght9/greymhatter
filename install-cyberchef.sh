#!/bin/bash

CURRENT_DIR="$1"

echo -n "Installing Cyberchef"
CWD=$(pwd)
mkdir -p /opt/cyberchef
cp $CURRENT_DIR/cyberchef/compose.yml
cd /opt/cyberchef
docker compose up -d
if [[ "$(docker inspect -f '{{.State.Running}}' cyberchef)" == "true" ]]; then
  echo -e "Cyberchef is running"
else
  echo -e "Cyberchef is not running"
fi
cd "$CWD"
