#!/bin/bash

USERNAME="$1"
PASSWORD="$2"

echo -e "Installing YETI CTI"
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
cd yeti-docker/prod
sed -i 's/- 80:80/- 8888:80/' docker-compose.yml
docker compose up -d
API = $(docker compose -p yeti exec -it api /docker-entrypoint.sh create-user $USERNAME $PASSWORD --admin)
if [[ "$API" == "*API key:*" ]]; then
  APIKEY = $($API | cut -d ":" -f 3 | xargs)
  sed -i s/YETI_API_ROOT = ''/YETI_API_ROOT = 'https://yeti-frontend/api/v2'/g /opt/timesketch/etc/timesketch/timesketch.conf
  sed -i s/YETI_API_KEY = ''/YEI_API_ROOT = '$APIKEY'/g /opt/timesketch/etc/timesketch/timesketch.conf
  echo -e "Yeti API key set for Timesketch"
else
  echo -e "Yeti API key not set in Timesketch"
fi
cd "$CWD"