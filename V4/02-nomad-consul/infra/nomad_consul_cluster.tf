# ==============================================================================
# 02-nomad-consul/infra/nomad_consul_cluster.tf
# Fully fixed and production-ready version – November 2025
# ==============================================================================

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

  # Fixed: advertise_addr = only IP, no http:// or port
  # retry_join uses LB IP only (works because we forward 8301 TCP below)
  consul_hcl = templatefile("${path.module}/../cloud-init-nomad-consul-servers/consul.hcl.tpl", {
    bootstrap_expect     = var.nomad_consul_instance_count
    advertise_addr_consul = "LOCAL_IP"
    consul_retry_join_ip  = var.nomad_consul_instance_count > 1 ? var.nomad_consul_lb_private_ip : "127.0.0.1"
  })

  nomad_hcl = templatefile("${path.module}/../cloud-init-nomad-consul-servers/nomad.hcl.tpl", {
    bootstrap_expect     = var.nomad_consul_instance_count
    advertise_addr_nomad  = "LOCAL_IP"
    vault_lb_address      = "http://${var.vault_lb_private_ip}:8200"
  })
}

# --------------------------------------------------------------------
# Resource Group, VNet, Subnet, NSG (unchanged – already perfect)
# --------------------------------------------------------------------
resource "azurerm_resource_group" "nomad_consul_rg" {
  name     = var.nomad_consul_rg_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "nomad_consul_vnet" {
  name              = var.nomad_consul_vnet_name
  address_space     = var.nomad_consul_vnet_address_space
  location          = azurerm_resource_group.nomad_consul_rg.location
  resource_group_name = azurerm_resource_group.nomad_consul_rg.name
  tags              = var.tags
}

resource "azurerm_subnet" "nomad_consul_subnet" {
  name                 = var.nomad_consul_subnet_name
  resource_group_name  = azurerm_resource_group.nomad_consul_rg.name
  virtual_network_name = azurerm_virtual_network.nomad_consul_vnet.name
  address_prefixes     = [var.nomad_consul_subnet_address_prefix]
}

resource "azurerm_network_security_group" "nomad_consul_nsg" {
  name                = "nsg-nomad-consul"
  location            = azurerm_resource_group.nomad_consul_rg.location
  resource_group_name = azurerm_resource_group.nomad_consul_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes      = var.ssh_allowed_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Consul-RPC-Serf"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
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
    destination_port_ranges    = ["8500-8501", "8600"]
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

# --------------------------------------------------------------------
# Internal Load Balancer – now correctly forwards 8301 TCP for Serf LAN
# --------------------------------------------------------------------
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
  name            = "backend-nomad-consul"
}

# Health Probes
resource "azurerm_lb_probe" "nomad_api_probe" {
  count           = var.nomad_consul_instance_count > 1 ? 1 : 0
  loadbalancer_id = azurerm_lb.nomad_consul_lb[0].id
  name            = "nomad-api-probe"
  protocol        = "Tcp"
  port            = var.nomad_lb_port
}

resource "azurerm_lb_probe" "consul_http_probe" {
  count           = var.nomad_consul_instance_count > 1 ? 1 : 0
  loadbalancer_id = azurerm_lb.nomad_consul_lb[0].id
  name            = "consul-http-probe"
  protocol        = "Tcp"
  port            = 8500
}

resource "azurerm_lb_probe" "consul_serf_probe" {
  count           = var.nomad_consul_instance_count > 1 ? 1 : 0
  loadbalancer_id = azurerm_lb.nomad_consul_lb[0].id
  name            = "consul-serf-probe"
  protocol        = "Tcp"
  port            = 8301
}

# Load Balancing Rules
resource "azurerm_lb_rule" "nomad_api" {
  count                     = var.nomad_consul_instance_count > 1 ? 1 : 0
  loadbalancer_id           = azurerm_lb.nomad_consul_lb[0].id
  name                      = "nomad-api"
  protocol                  = "Tcp"
  frontend_port             = var.nomad_lb_port
  backend_port              = var.nomad_lb_port
  frontend_ip_configuration_name = "internal"
  backend_address_pool_ids  = [azurerm_lb_backend_address_pool.nomad_consul_backend[0].id]
  probe_id                  = azurerm_lb_probe.nomad_api_probe[0].id
}

resource "azurerm_lb_rule" "consul_http" {
  count                     = var.nomad_consul_instance_count > 1 ? 1 : 0
  loadbalancer_id           = azurerm_lb.nomad_consul_lb[0].id
  name                      = "consul-http"
  protocol                  = "Tcp"
  frontend_port             = 8500
  backend_port              = 8500
  frontend_ip_configuration_name = "internal"
  backend_address_pool_ids  = [azurerm_lb_backend_address_pool.nomad_consul_backend[0].id]
  probe_id                  = azurerm_lb_probe.consul_http_probe[0].id
}

# Critical: Forward Serf LAN port 8301 TCP so retry_join works via LB
resource "azurerm_lb_rule" "consul_serf_lan" {
  count                     = var.nomad_consul_instance_count > 1 ? 1 : 0
  loadbalancer_id           = azurerm_lb.nomad_consul_lb[0].id
  name                      = "consul-serf-lan"
  protocol                  = "Tcp"
  frontend_port             = 8301
  backend_port              = 8301
  frontend_ip_configuration_name = "internal"
  backend_address_pool_ids  = [azurerm_lb_backend_address_pool.nomad_consul_backend[0].id]
  probe_id                  = azurerm_lb_probe.consul_serf_probe[0].id
}

# --------------------------------------------------------------------
# VMSS – with tag for future Azure auto-join (optional but recommended)
# --------------------------------------------------------------------
resource "azurerm_linux_virtual_machine_scale_set" "nomad_consul_vmss" {
  name                = "vmss-nomad-consul"
  location            = azurerm_resource_group.nomad_consul_rg.location
  resource_group_name = azurerm_resource_group.nomad_consul_rg.name
  sku                 = var.nomad_consul_vm_size
  instances           = var.nomad_consul_instance_count
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  overprovision       = false

  identity {
    type = "SystemAssigned"
  }

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
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.nomad_consul_subnet.id
      load_balancer_backend_address_pool_ids = var.nomad_consul_instance_count > 1 ? [azurerm_lb_backend_address_pool.nomad_consul_backend[0].id] : []

      public_ip_address {
        name                = "pip-nomad-consul-servers"
        idle_timeout_in_minutes = 30
        domain_name_label   = "nomad-consul-servers-${random_string.suffix.result}"
      }
    }
  }

  disable_password_authentication = false
  custom_data                     = local.nomad_consul_user_data

  tags = merge(var.tags, {
    ConsulCluster = "nomad-consul-servers"   # for future tag-based auto-join
  })
}


resource "azurerm_role_assignment" "consul_vmss_monitoring_reader" {
  scope                = azurerm_resource_group.nomad_consul_rg.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_linux_virtual_machine_scale_set.nomad_consul_vmss.identity[0].principal_id
}
