#!/usr/bin/env bash
# export-amd64-ova.sh — Export a greymhatter Proxmox template to an OVA file.
#
# Usage:
#   scripts/export-amd64-ova.sh <output_ova_path>
#
# Reads Proxmox connection info from packer/packer.auto.pkrvars.hcl.
# Optional env vars:
#   PROXMOX_SSH_USER  (default: root)
#   PROXMOX_SSH_KEY   (default: ssh-agent or ~/.ssh/id_rsa)
#
# What it does:
#   1. Queries the Proxmox API to find the most recent greymhatter-f42-amd64
#      template (excludes the base template vmid=9000).
#   2. SSH'es to the Proxmox node, exports the disk as raw, then runs
#      packer/scripts/export-ova.sh on the node to produce a stream-optimized
#      VMDK + OVF + manifest, packaged as an OVA.
#   3. SCPs the OVA back to the local output path.
#   4. Cleans up the remote staging directory.

set -euo pipefail

OUTPUT_OVA="${1:?usage: $0 <output_ova_path>}"
PKRVARS="packer/packer.auto.pkrvars.hcl"
EXPORT_SCRIPT="packer/scripts/export-ova.sh"

if [[ ! -f "$PKRVARS" ]]; then
  echo "ERROR: $PKRVARS not found (run from repo root)" >&2
  exit 1
fi

# Parse pkrvars — values are quoted, format: name = "value"
pv() { awk -F'"' "/^$1[[:space:]]*=/{print \$2; exit}" "$PKRVARS"; }
PROX_URL="$(pv proxmox_url)"
PROX_NODE="$(pv proxmox_node)"
PROX_USERNAME="$(pv proxmox_username)"
PROX_TOKEN="$(pv proxmox_token)"
VM_CPUS="$(awk -F'=' '/^vm_cpus[[:space:]]*=/{gsub(/ /,""); print $2; exit}' "$PKRVARS")"
VM_MEM="$(awk -F'=' '/^vm_memory[[:space:]]*=/{gsub(/ /,""); print $2; exit}' "$PKRVARS")"

PROX_HOST="$(echo "$PROX_URL" | sed -E 's|https?://||; s|:.*||')"
PROXMOX_SSH_USER="${PROXMOX_SSH_USER:-root}"
SSH_OPTS=("-o" "StrictHostKeyChecking=accept-new" "-o" "ConnectTimeout=10")
if [[ -n "${PROXMOX_SSH_KEY:-}" ]]; then
  SSH_OPTS+=("-i" "$PROXMOX_SSH_KEY")
fi

AUTH_HEADER="Authorization: PVEAPIToken=${PROX_USERNAME}=${PROX_TOKEN}"

echo "==> Locating most recent greymhatter-f42-amd64 template..."
VMID="$(curl -sk -H "$AUTH_HEADER" "${PROX_URL}/nodes/${PROX_NODE}/qemu" | python3 -c "
import json, sys
vms = json.load(sys.stdin)['data']
cand = [v for v in vms if v.get('template') and 'greymhatter-f42-amd64' in v['name'] and v['vmid'] != 9000]
cand.sort(key=lambda x: x['vmid'], reverse=True)
print(cand[0]['vmid'] if cand else '')
")"
if [[ -z "$VMID" ]]; then
  echo "ERROR: no greymhatter-f42-amd64 template found (excluding base vmid=9000)" >&2
  exit 1
fi
echo "    using vmid=$VMID"

REMOTE_STAGE="/tmp/gh-export-${VMID}"
echo "==> Uploading export script to $PROXMOX_SSH_USER@$PROX_HOST..."
ssh "${SSH_OPTS[@]}" "$PROXMOX_SSH_USER@$PROX_HOST" "rm -rf $REMOTE_STAGE && mkdir -p $REMOTE_STAGE/raw"
scp "${SSH_OPTS[@]}" "$EXPORT_SCRIPT" "$PROXMOX_SSH_USER@$PROX_HOST:$REMOTE_STAGE/export-ova.sh" >/dev/null

echo "==> Exporting disk + packaging on $PROX_HOST (this writes ~10-15 GB to /tmp)..."
ssh "${SSH_OPTS[@]}" "$PROXMOX_SSH_USER@$PROX_HOST" "
  set -e
  # Resolve the scsi0 volid (e.g. local-lvm-thin-01:base-100-disk-0) and its block path
  VOLID=\$(qm config $VMID | awk -F'[ ,]' '/^scsi0:/{print \$2; exit}')
  DISK_PATH=\$(pvesm path \"\$VOLID\")
  LV_REF=\$(echo \"\$VOLID\" | tr ':' '/')   # local-lvm-thin-01/base-100-disk-0
  echo \"  volid=\$VOLID  path=\$DISK_PATH  lv=\$LV_REF\"
  # Template base disks have the 'skip activation' flag set; activate explicitly
  # with -K, then deactivate when we're done.
  lvchange -ay -K \"\$LV_REF\" 2>&1 || true
  trap 'lvchange -an -K \"'\"\$LV_REF\"'\" 2>/dev/null || true' EXIT
  qemu-img convert -f raw -O raw \"\$DISK_PATH\" $REMOTE_STAGE/raw/disk.raw
  bash $REMOTE_STAGE/export-ova.sh $REMOTE_STAGE/raw greymhatter-f42 amd64 $VM_CPUS $VM_MEM
"

REMOTE_OVA="$REMOTE_STAGE/ova-amd64/greymhatter-f42-amd64.ova"
echo "==> Downloading OVA to $OUTPUT_OVA..."
mkdir -p "$(dirname "$OUTPUT_OVA")"
scp "${SSH_OPTS[@]}" "$PROXMOX_SSH_USER@$PROX_HOST:$REMOTE_OVA" "$OUTPUT_OVA"

echo "==> Cleaning up remote staging..."
ssh "${SSH_OPTS[@]}" "$PROXMOX_SSH_USER@$PROX_HOST" "rm -rf $REMOTE_STAGE"

echo ""
echo "  OVA exported: $OUTPUT_OVA"
du -h "$OUTPUT_OVA"
echo ""
