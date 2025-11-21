#cloud-config
package_update: true
write_files:
  - path: /usr/local/bin/01-install-prereqs.sh
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -euo pipefail
      apt-get update -y && apt-get install -y curl unzip jq
  - path: /usr/local/bin/02-install-hashi-tools.sh
    permissions: "0755"
    content: |
      ${install_tools_content}
  - path: /etc/consul.d/consul-client.hcl
    permissions: "0644"
    content: |
      ${consul_client_hcl}
  - path: /etc/nomad.d/nomad-client.hcl
    permissions: "0644"
    content: |
      ${nomad_client_hcl}
  - path: /etc/systemd/system/consul.service
    permissions: "0644"
    content: |
      ${consul_service}
  - path: /etc/systemd/system/nomad.service
    permissions: "0644"
    content: |
      ${nomad_service}

runcmd:
  - useradd --system --home /etc/consul.d --shell /bin/false consul || echo "consul user already exists"
  - useradd --system --home /etc/nomad.d --shell /bin/false nomad || echo "nomad user already exists"
  - mkdir -p /etc/consul.d /etc/nomad.d /opt/consul/data /opt/nomad/data
  - chown -R consul:consul /etc/consul.d /opt/consul
  - chown -R nomad:nomad /etc/nomad.d /opt/nomad
  - /usr/local/bin/01-install-prereqs.sh
  - /usr/local/bin/02-install-hashi-tools.sh
  - systemctl daemon-reload
  - systemctl enable --now consul
  - sleep 10
  - systemctl enable --now nomad