#!/usr/bin/env bash
# Clones the GreymHatter base VM on standalone ESXi via ovftool, powers it on,
# polls vmtools for the IP, and prints the IP to stdout. All progress messages
# go to stderr so the caller can capture just the IP via `IP=$(clone-esxi.sh)`.
#
# Why ovftool: standalone ESXi (no vCenter license) lacks the Clone API that
# Packer's vsphere-clone source uses. ovftool can deploy a new VM from an
# existing one through the public REST/SOAP interface that IS exposed on
# standalone ESXi.
#
# Why govc: same reason — querying a guest's reported IP via the standalone
# ESXi API. Both tools talk to the same SOAP endpoint, just different concerns.

set -euo pipefail

PKRVARS="${PKRVARS:-packer/packer.auto.pkrvars.hcl}"

if [[ ! -f "$PKRVARS" ]]; then
    echo "ERROR: pkrvars file not found at $PKRVARS" >&2
    exit 1
fi

# --- Read connection details from pkrvars ---
ESX_URL=$(awk -F'"' '/^esx_url[[:space:]]*=/{print $2}' "$PKRVARS")
ESX_USER=$(awk -F'"' '/^esx_username[[:space:]]*=/{print $2}' "$PKRVARS")
ESX_PASS=$(awk -F'"' '/^esx_password[[:space:]]*=/{print $2}' "$PKRVARS")
ESX_DS=$(awk -F'"' '/^esx_storage[[:space:]]*=/{print $2}' "$PKRVARS")

# Strip protocol → host:port for use in vi:// URLs and govc
ESX_HOSTNAME=$(printf '%s' "$ESX_URL" | sed -E 's|^https?://||')

# URL-encode credentials (handle special characters in password)
ENC_USER=$(printf '%s' "$ESX_USER" | python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(), safe=""))')
ENC_PASS=$(printf '%s' "$ESX_PASS" | python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(), safe=""))')

SOURCE_VM="${SOURCE_VM:-greymhatter-f42-esxi-base}"
TARGET_VM="${TARGET_VM:-greymhatter-f42-esxi-$(date +%Y%m%d)}"

OVFTOOL="${OVFTOOL:-/Applications/VMware Fusion.app/Contents/Library/VMware OVF Tool/ovftool}"

# --- Tool checks ---
[[ -x "$OVFTOOL" ]] || { echo "ERROR: ovftool not at $OVFTOOL (install VMware Fusion)" >&2; exit 1; }
command -v govc >/dev/null 2>&1 || { echo "ERROR: govc not found (brew install govc)" >&2; exit 1; }

# govc env (used after the clone for power-on + IP polling)
export GOVC_URL="https://${ESX_HOSTNAME}/sdk"
export GOVC_USERNAME="$ESX_USER"
export GOVC_PASSWORD="$ESX_PASS"
export GOVC_INSECURE=1

# --- Sanity: source VM exists, target doesn't ---
if ! govc vm.info "$SOURCE_VM" >/dev/null 2>&1; then
    echo "ERROR: source VM '$SOURCE_VM' not found on ESXi (run \`make base-esxi\` first)" >&2
    exit 1
fi
if govc vm.info "$TARGET_VM" 2>/dev/null | grep -q '^Name:'; then
    echo "ERROR: target VM '$TARGET_VM' already exists — delete it or set TARGET_VM=<other-name>" >&2
    exit 1
fi

echo "==> Cloning $SOURCE_VM → $TARGET_VM via ovftool" >&2
"$OVFTOOL" \
    --noSSLVerify \
    --acceptAllEulas \
    --datastore="$ESX_DS" \
    --diskMode=thin \
    --name="$TARGET_VM" \
    "vi://${ENC_USER}:${ENC_PASS}@${ESX_HOSTNAME}/${SOURCE_VM}" \
    "vi://${ENC_USER}:${ENC_PASS}@${ESX_HOSTNAME}/" >&2

echo "==> Clone complete. Powering on $TARGET_VM" >&2
govc vm.power -on "$TARGET_VM" >&2

echo "==> Waiting for vmtools-reported IP (up to 5 min)" >&2
IP=""
for i in $(seq 1 60); do
    # vm.ip blocks until vmtools is up; --v4 filters to IPv4 only
    IP=$(govc vm.ip -v4 -wait=5s "$TARGET_VM" 2>/dev/null | head -1 || true)
    if [[ -n "$IP" && "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "==> VM IP: $IP" >&2
        echo "$IP"          # stdout — the only thing the caller cares about
        exit 0
    fi
    sleep 1
done

echo "ERROR: VM '$TARGET_VM' did not report IP within timeout" >&2
exit 1
