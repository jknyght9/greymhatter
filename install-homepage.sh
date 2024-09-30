#!/bin/bash

CURRENT_DIR="$1"

CWD=$(pwd)
cd /opt 
mkdir -p homepage
cp -R $CURRENT_DIR/homepage/* /opt/homepage/ 
docker compose up -d
cd "$CWD"
