# locals block to prepare cloud-init and HCL templates
locals {
  nomad_consul_user_data = base64encode(templatefile("${path.module}/../cloud-init-nomad-consul-servers/user-data.yaml.tpl", {
    create_users_content   = indent(6, file("${path.module}/../cloud-init-nomad-consul-servers/create-users.sh"))
    install_tools_content  = indent(6, file("${path.module}/../cloud-init-nomad-consul-servers/install-hashi-tools.sh"))
    prereqs_content        = indent(6, file("${path.module}/../cloud-init-nomad-consul-servers/install-prereqs.sh"))
    consul_hcl_content     = indent(6, local.consul_hcl)
    nomad_hcl_content      = indent(6, local.nomad_hcl)
    consul_service_content = indent(6, file("${path.module}/../cloud-init-nomad-consul-servers/consul.service"))
    nomad_service_content  = indent(6, file("${path.module}/../cloud-init-nomad-consul-servers/nomad.service"))
  }))

  consul_hcl = templatefile("${path.module}/../cloud-init-nomad-consul-servers/consul.hcl.tpl", {
    bootstrap_expect = var.nomad_consul_instance_count
    # In HA mode, point to the LB. In single-node mode, point to self.
    leader_api_addr  = var.nomad_consul_instance_count > 1 ? "http://${var.nomad_consul_lb_private_ip}:8500" : "http://LOCAL_IP:8500"
    advertise_addr_consul = "http://LOCAL_IP:8500"
  })

  nomad_hcl = templatefile("${path.module}/../cloud-init-nomad-consul-servers/nomad.hcl.tpl", {
    bootstrap_expect = var.nomad_consul_instance_count
    advertise_addr_nomad = "LOCAL_IP"
    vault_lb_address = "http://${var.vault_lb_private_ip}:8200"
  })
}

# Resource Group and VNet
resource "azurerm_resource_group" "nomad_consul_rg" {
  name     = var.nomad_consul_rg_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "nomad_consul_vnet" {
  name                = var.nomad_consul_vnet_name
  address_space       = var.nomad_consul_vnet_address_space
  location            = azurerm_resource_group.nomad_consul_rg.location
  resource_group_name = azurerm_resource_group.nomad_consul_rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "nomad_consul_subnet" {
  name                 = var.nomad_consul_subnet_name
  resource_group_name  = azurerm_resource_group.nomad_consul_rg.name
  virtual_network_name = azurerm_virtual_network.nomad_consul_vnet.name
  address_prefixes     = [var.nomad_consul_subnet_address_prefix]
}

# NSG for Nomad/Consul
resource "azurerm_network_security_group" "nomad_consul_nsg" {
  name                = "nsg-nomad-consul"
  location            = azurerm_resource_group.nomad_consul_rg.location
  resource_group_name = azurerm_resource_group.nomad_consul_rg.name

  security_rule {
    name                  = "SSH"
    priority              = 1001
    direction             = "Inbound"
    access                = "Allow"
    protocol              = "Tcp"
    source_port_range     = "*"
    destination_port_range = "22"
    source_address_prefix = var.ssh_allowed_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Consul-RPC-Serf" # Gossip
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*" # TCP and UDP
    source_port_range          = "*"
    destination_port_ranges    = ["8300-8302"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Consul-API-UI"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8500-8501", "8600"] # API, DNS
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Nomad-API-RPC"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["4646-4648"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nomad_consul_subnet_nsg" {
  subnet_id                 = azurerm_subnet.nomad_consul_subnet.id
  network_security_group_id = azurerm_network_security_group.nomad_consul_nsg.id
}

# Internal LB for Nomad/Consul
resource "azurerm_lb" "nomad_consul_lb" {
  count               = var.nomad_consul_instance_count > 1 ? 1 : 0
  name                = "lb-nomad-internal"
  location            = azurerm_resource_group.nomad_consul_rg.location
  resource_group_name = azurerm_resource_group.nomad_consul_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.nomad_consul_subnet.id
    private_ip_address            = var.nomad_consul_lb_private_ip
    private_ip_address_allocation = "Static"
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "nomad_consul_backend" {
  count           = var.nomad_consul_instance_count > 1 ? 1 : 0
  loadbalancer_id = azurerm_lb.nomad_consul_lb[0].id
  name            = "backend-nomad-consul" # Renamed for clarity
}

# --- Probes for Nomad and Consul ---
resource "azurerm_lb_probe" "nomad_probe" {
  count           = var.nomad_consul_instance_count > 1 ? 1 : 0
  loadbalancer_id = azurerm_lb.nomad_consul_lb[0].id
  name            = "tcp-probe-nomad-api"
  port            = var.nomad_lb_port
  protocol        = "Tcp"
}

resource "azurerm_lb_probe" "consul_probe" {
  count           = var.nomad_consul_instance_count > 1 ? 1 : 0
  loadbalancer_id = azurerm_lb.nomad_consul_lb[0].id
  name            = "tcp-probe-consul-api"
  port            = 8500 # Consul API port
  protocol        = "Tcp"
}


# --- Rules for Nomad and Consul ---
resource "azurerm_lb_rule" "nomad_rule" {
  count                          = var.nomad_consul_instance_count > 1 ? 1 : 0
  loadbalancer_id                = azurerm_lb.nomad_consul_lb[0].id
  name                           = "nomad-api-rule"
  protocol                       = "Tcp"
  frontend_port                  = var.nomad_lb_port
  backend_port                   = var.nomad_lb_port
  frontend_ip_configuration_name = "internal"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.nomad_consul_backend[0].id]
  probe_id                       = azurerm_lb_probe.nomad_probe[0].id
}

resource "azurerm_lb_rule" "consul_rule" {
  count                          = var.nomad_consul_instance_count > 1 ? 1 : 0
  loadbalancer_id                = azurerm_lb.nomad_consul_lb[0].id
  name                           = "consul-api-rule"
  protocol                       = "Tcp"
  frontend_port                  = 8500 # Expose Consul API on the LB
  backend_port                   = 8500
  frontend_ip_configuration_name = "internal"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.nomad_consul_backend[0].id]
  probe_id                       = azurerm_lb_probe.consul_probe[0].id
}

# VMSS for Nomad/Consul
resource "azurerm_linux_virtual_machine_scale_set" "nomad_consul_vmss" {
  name                = "vmss-nomad-consul"
  location            = azurerm_resource_group.nomad_consul_rg.location
  resource_group_name = azurerm_resource_group.nomad_consul_rg.name
  sku                 = var.nomad_consul_vm_size
  instances           = var.nomad_consul_instance_count
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  overprovision       = false

  # Identity is no longer needed for auto-join
  # identity {
  #   type = "SystemAssigned"
  # }

  source_image_reference {
    publisher = var.nomad_consul_image_publisher
    offer     = var.nomad_consul_image_offer
    sku       = var.nomad_consul_image_sku
    version   = var.nomad_consul_image_version
  }

  os_disk {
    storage_account_type = var.os_disk_type
    caching              = "ReadWrite"
    disk_size_gb         = var.os_disk_size_gb
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.nomad_consul_subnet.id
      load_balancer_backend_address_pool_ids = var.nomad_consul_instance_count > 1 ? [azurerm_lb_backend_address_pool.nomad_consul_backend[0].id] : []

      public_ip_address {                 
        name                    = "pip-nomad-consul-servers"
        idle_timeout_in_minutes = 30
        domain_name_label       = "nomad-consul-servers-${random_string.suffix.result}"
      }
    }
  }

  disable_password_authentication = false
  custom_data                       = local.nomad_consul_user_data

  # Tag for auto-join is no longer needed
  tags = var.tags
}
