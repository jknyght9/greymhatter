#!/usr/bin/env bash
# upload-release.sh — Publish OVA/zip artifacts in output/ to Cloudflare R2.
#
# Usage:
#   scripts/upload-release.sh [TAG]
#
# TAG is the release tag (e.g. v2.0.0). Default: latest annotated tag.
# Artifacts must already exist in output/ (built via `make build-* && make export-*`).
#
# Layout on R2:
#   <bucket>/<TAG>/greymhatter-f42-amd64-YYYYMMDD.SHA.ova
#   <bucket>/<TAG>/greymhatter-f42-arm64-YYYYMMDD.SHA.zip
#   <bucket>/<TAG>/SHA256SUMS
#
# Requires:
#   - rclone configured with a remote named 'r2-greymhatter'
#     (see docs/build-pipeline.md)
#   - sha256sum (coreutils) or shasum (default on macOS)
#
# Env overrides:
#   R2_REMOTE         rclone remote name           (default: r2-greymhatter)
#   R2_BUCKET         R2 bucket name               (default: greymhatter-releases)
#   R2_PUBLIC_BASE    Public URL prefix for the bucket. Printed at end so
#                     the maintainer can paste links into the GitHub Release.
#                     Default: empty (skip URL printing).

set -euo pipefail

REMOTE="${R2_REMOTE:-r2-greymhatter}"
BUCKET="${R2_BUCKET:-greymhatter-releases}"
PUBLIC_BASE="${R2_PUBLIC_BASE:-}"
OUT=output

TAG="${1:-$(git describe --tags --abbrev=0 2>/dev/null || true)}"
if [[ -z "$TAG" ]]; then
  echo "ERROR: no tag passed and no annotated tag in repo." >&2
  echo "       Usage: $0 v2.0.0" >&2
  exit 1
fi

if ! command -v rclone >/dev/null; then
  echo "ERROR: rclone not installed. brew install rclone" >&2
  exit 1
fi

if ! rclone listremotes | grep -qx "${REMOTE}:"; then
  echo "ERROR: rclone remote '${REMOTE}' not configured. Run 'rclone config'." >&2
  exit 1
fi

shopt -s nullglob
artifacts=("$OUT"/greymhatter-f42-*.ova "$OUT"/greymhatter-f42-*.zip)
if [[ ${#artifacts[@]} -eq 0 ]]; then
  echo "ERROR: no greymhatter-f42-*.{ova,zip} in $OUT/. Build first." >&2
  exit 1
fi

# coreutils sha256sum produces the format we want directly; macOS shasum needs
# slight massaging. Test once, define a wrapper.
if command -v sha256sum >/dev/null; then
  _sha() { sha256sum "$1"; }
else
  _sha() { shasum -a 256 "$1"; }
fi

echo "==> Tag:    $TAG"
echo "==> Remote: ${REMOTE}:${BUCKET}/${TAG}/"
echo "==> Artifacts:"
for f in "${artifacts[@]}"; do
  printf '    %s  (%s)\n' "$(basename "$f")" "$(du -h "$f" | cut -f1)"
done

# Generate SHA256SUMS in canonical "<sum>  <filename>" format alongside artifacts.
# Filenames in the manifest are basenames only so the file is portable.
SUMS="$OUT/SHA256SUMS"
: > "$SUMS"
for f in "${artifacts[@]}"; do
  echo "==> sha256: $(basename "$f")"
  ( cd "$OUT" && _sha "$(basename "$f")" ) >> "$SUMS"
done

echo "==> Uploading to ${REMOTE}:${BUCKET}/${TAG}/"
rclone copy "$OUT" "${REMOTE}:${BUCKET}/${TAG}/" \
  --include "greymhatter-f42-*.ova" \
  --include "greymhatter-f42-*.zip" \
  --include "SHA256SUMS" \
  --progress --transfers 4 --checksum

echo
echo "==> Upload complete."
if [[ -n "$PUBLIC_BASE" ]]; then
  echo "    Public URLs:"
  for f in "${artifacts[@]}"; do
    printf '    %s/%s/%s\n' "${PUBLIC_BASE%/}" "$TAG" "$(basename "$f")"
  done
  printf '    %s/%s/SHA256SUMS\n' "${PUBLIC_BASE%/}" "$TAG"
else
  echo "    Set R2_PUBLIC_BASE=https://… to print download URLs."
fi
