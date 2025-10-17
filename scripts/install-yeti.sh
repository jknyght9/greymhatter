#!/bin/bash

USERNAME="$1"
PASSWORD="$2"

CWD=$(pwd)
if ! grep -q "sse4_2" /proc/cpuinfo; then
  echo "SSE4.2 is not supported by your CPU. This is required by the database."
  exit 1
fi  
if ! grep -q "avx" /proc/cpuinfo; then
  echo "AVX is not supported by your CPU. This is required by the database."
  exit 1
fi
cd /opt/
git clone https://github.com/yeti-platform/yeti-docker
cd /opt/yeti-docker/prod
sed -i 's/- 80:80/- 8888:80/' docker-compose.yaml
echo -e "Initializing Yeti"
./init.sh
API=$(docker compose run --rm api create-user "$USERNAME" "$PASSWORD" --admin)
if [[ "$API" == *"API key:"* ]]; then
  APIKEY=$(echo "$API" | grep -oP "(?<=API key: ).*")
  sed -i "s#YETI_API_ROOT = ''#YETI_API_ROOT = 'https://localhost:8000/api/v2'#g" /opt/timesketch/etc/timesketch/timesketch.conf
  sed -i "s#YETI_API_KEY = ''#YETI_API_KEY = '$APIKEY'#g" /opt/timesketch/etc/timesketch/timesketch.conf
  echo -e "Yeti API key set for Timesketch"
else
  echo -e "Yeti API key not set in Timesketch"
fi
cd "$CWD"
