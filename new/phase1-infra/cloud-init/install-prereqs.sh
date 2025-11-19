# New file: phase1-infra/cloud-init/01-install-prereqs.sh
#!/usr/bin/env bash
set -euo pipefail

# Retry loop for apt-get to handle transient cloud networking issues
for i in {1..12}; do
  if apt-get update -y && apt-get install -y curl unzip jq; then
    echo "[cloud-init] Prereqs installed successfully."
    exit 0
  fi
  echo "[cloud-init] apt retry $i/12..."
  sleep 10
done
echo "[cloud-init] Failed to install prerequisites after retries." >&2
exit 1