#!/usr/bin/env bash
# FILE: cloud-init/install-prereqs.sh
set -euo pipefail   # now safe because we use bash explicitly

echo "[cloud-init] Installing prerequisites (curl, unzip, jq)..."

for i in {1..10}; do
  if apt-get update -y && apt-get install -y curl unzip jq; 2>/dev/null; then
    echo "[cloud-init] Prerequisites installed successfully."
    exit 0
  fi
  echo "[cloud-init] Attempt $i failed, retrying in 10s..."
  sleep 10
done

echo "[cloud-init] ERROR: Failed to install prerequisites after 10 attempts."
exit 1