#!/usr/bin/env bash
set -euo pipefail

# ===================================================================
# install-hashi-tools.sh – Idempotent installer for Consul + Nomad
# Updated: November 2025 – rock-solid for Azure VMSS + cloud-init
# ===================================================================

# Use latest stable versions (as of Nov 2025) – change only if you have a reason
CONSUL_VERSION="1.20.2"   # Fixed memberlist spam + many improvements
NOMAD_VERSION="1.8.5"     # Latest 1.8.x with bugfixes (1.9+ changes too much)

echo "[install-hashi-tools] Installing Consul ${CONSUL_VERSION} and Nomad ${NOMAD_VERSION}..."

# Ensure we're in a temp dir and clean up on exit
cd /tmp
trap 'rm -f consul*.zip nomad*.zip consul nomad 2>/dev/null || true' EXIT

# -------------------------------------------------------------------
# Helper: install binary safely
# -------------------------------------------------------------------
install_binary() {
  local name="$1"
  local version="$2"
  local bin_path="/usr/local/bin/${name}"

  if command -v "$name" >/dev/null 2>&1; then
    current_version=$("$name" version | head -n1 | awk '{print $2}' || true)
    echo "[install-hashi-tools] $name already installed ($current_version)"
    return 0
  fi

  echo "[install-hashi-tools] Downloading ${name}_${version}_linux_amd64.zip..."
  curl -fsSLO --retry 5 --retry-delay 2 \
    "https://releases.hashicorp.com/${name}/${version}/${name}_${version}_linux_amd64.zip"

  echo "[install-hashi-tools] Extracting and installing $name..."
  unzip -qo "${name}_${version}_linux_amd64.zip"
  sudo install -m 0755 -o root -g root "$name" "$bin_path"

  echo "[install-hashi-tools] $name ${version} installed successfully."
}

# -------------------------------------------------------------------
# Install Consul
# -------------------------------------------------------------------
install_binary consul "$CONSUL_VERSION"

# -------------------------------------------------------------------
# Install Nomad
# -------------------------------------------------------------------
install_binary nomad "$NOMAD_VERSION"

# -------------------------------------------------------------------
# Final sanity checks + refresh linker cache (critical on minimal Azure images)
# -------------------------------------------------------------------
echo "[install-hashi-tools] Running final checks..."
sudo ldconfig  # Fixes "status=203/EXEC" on minimal Ubuntu images

echo "[install-hashi-tools] All done! Versions:"
consul version | head -n1
nomad version  | head -n1

echo "[install-hashi-tools] HashiCorp tools ready and operational!"