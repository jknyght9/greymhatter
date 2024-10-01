#!/bin/bash

CURRENT_DIR="$1"

CWD=$(pwd)
mkdir -p /opt/cyberchef
cp $CURRENT_DIR/cyberchef/compose.yml /opt/cyberchef/
cd /opt/cyberchef
docker compose up -d
if [[ "$(docker inspect -f '{{.State.Running}}' cyberchef)" == "true" ]]; then
  echo -e "Cyberchef is running"
else
  echo -e "Cyberchef is not running"
fi
cd "$CWD"
