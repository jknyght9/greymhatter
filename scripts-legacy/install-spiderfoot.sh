#!/bin/bash

CURRENT_DIR="$1"

CWD=$(pwd)
cd /opt
git clone https://github.com/smicallef/spiderfoot.git
cd spiderfoot
docker build -t spiderfoot .
cp $CURRENT_DIR/docker/spiderfoot/compose.yml /opt/spiderfoot
cd /opt/spiderfoot
docker compose up -d
if [[ "$(docker inspect -f '{{.State.Running}}' spiderfoot)" == "true" ]]; then
  echo -e "Spiderfoot is running"
else
  echo -e "Spiderfoot is not running"
fi
cd "$CWD"
