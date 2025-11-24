#cloud-config
package_update: true
write_files:

  - path: /usr/local/bin/00-create-users.sh
    permissions: "0755"
    owner: root:root
    content: |
      ${create_users_content}

  - path: /usr/local/bin/01-install-prereqs.sh
    permissions: "0755"
    owner: root:root
    content: |
      ${prereqs_content}

  - path: /usr/local/bin/02-install-hashi-tools.sh
    permissions: "0755"
    owner: root:root
    content: |
      ${install_tools_content}

  - path: /etc/consul.d/consul.hcl
    permissions: "0640"
    owner: root:root 
    content: |
      ${consul_hcl_content}

  - path: /etc/nomad.d/nomad.hcl
    permissions: "0640"
    owner: root:root 
    content: |
      ${nomad_hcl_content}

  - path: /etc/systemd/system/consul.service
    permissions: "0644"
    owner: root:root
    content: |
      ${consul_service_content}

  - path: /etc/systemd/system/nomad.service
    permissions: "0644"
    owner: root:root
    content: |
      ${nomad_service_content}

runcmd:
  - /usr/local/bin/00-create-users.sh
  - /usr/local/bin/01-install-prereqs.sh
  - /usr/local/bin/02-install-hashi-tools.sh   # installs both Consul + Nomad binaries early (safe & idempotent)

  - |
    PRIVATE_IP=$(hostname -I | awk '{print $1}' | tr -d '[:space:]')
    echo "[cloud-init] Detected private IP: $PRIVATE_IP"
    sed -i "s/LOCAL_IP/$PRIVATE_IP/g" /etc/nomad.d/nomad.hcl
    sed -i "s/LOCAL_IP/$PRIVATE_IP/g" /etc/consul.d/consul.hcl

  - systemctl daemon-reload

  # Start Consul first
  - systemctl enable --now consul

  # Wait until Consul is fully healthy (API responding + leader elected (leader elected)
  - |
    echo "[cloud-init] Waiting for Consul to be healthy and leader elected..."
    timeout 120 bash -c '
      until curl -fs http://127.0.0.1:8500/v1/status/leader | grep -q ':"[0-9]\+\.[0-9]\+\.[0-9]\+:[0-9]\+:[0-9]+\""; do
      sleep 5
    done
    echo "[cloud-init] Consul is healthy and has a leader elected leader!"
    ' || (echo "[cloud-init] Consul failed to become healthy in 2 minutes" && exit 1)

  # NOW start Nomad - only when Consul is guaranteed healthy
  - systemctl enable --now nomad