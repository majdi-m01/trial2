#!/usr/bin/env bash
set -euo pipefail

echo "[cloud-init] Creating system users 'nomad' and 'consul'..."
if ! id "consul" >/dev/null 2>&1; then
    useradd --system --home /etc/consul.d --shell /bin/false consul
else
    echo "[cloud-init] User 'consul' already exists."
fi
if ! id "nomad" >/dev/null 2>&1; then
    useradd --system --home /etc/nomad.d --shell /bin/false nomad
else
    echo "[cloud-init] User 'nomad' already exists."
fi

echo "[cloud-init] Creating required directories..."
mkdir -p /etc/consul.d /etc/nomad.d /opt/consul/data /opt/nomad/data
chown -R consul:consul /etc/consul.d /opt/consul
chown -R nomad:nomad /etc/nomad.d /opt/nomad