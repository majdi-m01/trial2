#!/usr/bin/env bash
set -euo pipefail

CONSUL_VERSION="1.19.0"
NOMAD_VERSION="1.8.0"

echo "[cloud-init] Installing Consul ${CONSUL_VERSION} and Nomad ${NOMAD_VERSION}..."

cd /tmp

# Install Consul
if ! command -v consul >/dev/null 2>&1; then
    echo "[cloud-init] Downloading consul_${CONSUL_VERSION}_linux_amd64.zip..."
    curl -fsSLO "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip"
    unzip "consul_${CONSUL_VERSION}_linux_amd64.zip"
    install -m 0755 consul /usr/local/bin/consul
    rm -f consul "consul_${CONSUL_VERSION}_linux_amd64.zip"
    echo "[cloud-init] Consul ${CONSUL_VERSION} installed."
else
    echo "[cloud-init] Consul already installed ($(consul version))."
fi

# Install Nomad
if ! command -v nomad >/dev/null 2>&1; then
    echo "[cloud-init] Downloading nomad_${NOMAD_VERSION}_linux_amd64.zip..."
    curl -fsSLO "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip"
    echo "[cloud-init] Unzipping..."
    unzip "nomad_${NOMAD_VERSION}_linux_amd64.zip"
    install -m 0755 nomad /usr/local/bin/nomad
    rm -f nomad "nomad_${NOMAD_VERSION}_linux_amd64.zip"
    echo "[cloud-init] Nomad ${NOMAD_VERSION} installed."
else
    echo "[cloud-init] Nomad already installed ($(nomad version))."
fi

echo "[cloud-init] HashiCorp tools installed successfully!"
consul version
nomad version