#!/bin/bash
# Start (or restart) the local Docker Hub pull-through cache on the Mac.
# Reads credentials from .registry-mirror.env (gitignored).
set -euo pipefail

ENV_FILE="$(dirname "$0")/../.registry-mirror.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Missing $ENV_FILE — create it with REGISTRY_PROXY_USERNAME and REGISTRY_PROXY_PASSWORD"
    exit 1
fi

docker stop greymhatter-registry-mirror >/dev/null 2>&1 || true
docker rm   greymhatter-registry-mirror >/dev/null 2>&1 || true

docker run -d --name greymhatter-registry-mirror \
    --restart=unless-stopped \
    --env-file "$ENV_FILE" \
    -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
    -p 5050:5000 \
    -v greymhatter-registry-data:/var/lib/registry \
    ghcr.io/distribution/distribution:3.0.0

sleep 3
docker ps --filter name=greymhatter-registry-mirror --format '{{.Names}}  {{.Status}}'
