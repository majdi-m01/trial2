#cloud-config
package_update: true
write_files:
  - path: /usr/local/bin/01-install-prereqs.sh
    permissions: "0755"
    owner: root:root
    content: |
      ${prereqs_content}

  - path: /usr/local/bin/00-create-users.sh
    permissions: "0755"
    owner: root:root
    content: |
      ${create_users_content}

  - path: /usr/local/bin/02-install-hashi-tools.sh
    permissions: "0755"
    owner: root:root
    content: |
      ${install_tools_content}

  - path: /etc/consul.d/consul.hcl
    permissions: "0640"
    owner: consul:consul
    content: |
      ${consul_hcl_content}

  - path: /etc/nomad.d/nomad.hcl
    permissions: "0640"
    owner: nomad:nomad
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
  - /usr/local/bin/01-install-prereqs.sh
  - /usr/local/bin/00-create-users.sh
  - /usr/local/bin/02-install-hashi-tools.sh

  - |
    PRIVATE_IP=$(hostname -I | awk '{print $1}' | tr -d '[:space:]')
    echo "[cloud-init] Detected private IP: $PRIVATE_IP"
    sed -i "s/LOCAL_IP/$PRIVATE_IP/g" /etc/nomad.d/nomad.hcl

  - systemctl daemon-reload
  - systemctl enable --now consul
  - sleep 15
  - systemctl enable --now nomad