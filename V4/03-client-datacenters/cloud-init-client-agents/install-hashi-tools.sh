#!/usr/bin/env bash
set -euo pipefail

CONSUL_VERSION="1.19.0"
NOMAD_VERSION="1.8.0"

echo "[cloud-init] Installing Consul ${CONSUL_VERSION} and Nomad ${NOMAD_VERSION}..."
cd /tmp

# Install Consul
if ! command -v consul >/dev/null 2>&1; then
    curl -fsSLO "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip"
    unzip "consul_${CONSUL_VERSION}_linux_amd64.zip"
    install -m 0755 consul /usr/local/bin/consul
    rm -f consul *.zip
fi

# Install Nomad
if ! command -v nomad >/dev/null 2>&1; then
    curl -fsSLO "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip"
    unzip "nomad_${NOMAD_VERSION}_linux_amd64.zip"
    install -m 0755 nomad /usr/local/bin/nomad
    rm -f nomad *.zip
fi