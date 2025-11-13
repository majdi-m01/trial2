# ==============================================================================
# PROVIDERS AND DATA SOURCES
# ==============================================================================

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}

resource "random_string" "unique" {
  length  = 4
  special = false
  upper   = false
  numeric = true
  lower   = true
}

# ==============================================================================
# LOCAL VARIABLES FOR LOGIC
# ==============================================================================

locals {
  # Server-side subnets (fixed roles)
  server_vnet_cidr  = var.server_vnet_cidr
  vault_subnet_cidr = var.vault_subnet_cidr
  core_subnet_cidr  = var.core_subnet_cidr

  # Per-datacenter client subnets map
  client_subnets = {
    for dc_key, dc_val in var.datacenters : dc_key => {
      cidr = dc_val.subnet_cidr
    }
  }

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
  })

}

# ==============================================================================
# RESOURCE GROUPS
# ==============================================================================

resource "azurerm_resource_group" "servers_rg" {
  name     = "${var.project_name}-servers-rg"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "clients_rgs" {
  for_each = var.datacenters
  name     = "${var.project_name}-${each.key}-rg"
  location = var.location
  tags     = local.common_tags
}

# ==============================================================================
# SERVER NETWORKING (VNet + Subnets + NSGs)
# ==============================================================================

resource "azurerm_virtual_network" "server_vnet" {
  name                = "${var.project_name}-server-vnet"
  address_space       = [local.server_vnet_cidr]
  location            = azurerm_resource_group.servers_rg.location
  resource_group_name = azurerm_resource_group.servers_rg.name
  tags                = local.common_tags
}

resource "azurerm_subnet" "vault_subnet" {
  name                 = "vault-subnet"
  resource_group_name  = azurerm_resource_group.servers_rg.name
  virtual_network_name = azurerm_virtual_network.server_vnet.name
  address_prefixes     = [local.vault_subnet_cidr]
}

resource "azurerm_subnet" "core_subnet" {
  name                 = "core-subnet"
  resource_group_name  = azurerm_resource_group.servers_rg.name
  virtual_network_name = azurerm_virtual_network.server_vnet.name
  address_prefixes     = [local.core_subnet_cidr]
}

# NSGs per subnet (restrict SSH to admin IPs; tighten app ports later)
resource "azurerm_network_security_group" "vault_nsg" {
  name                = "${var.project_name}-vault-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.servers_rg.name
  tags                = local.common_tags

  security_rule {
    name                       = "AllowSSHFromAdmin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.admin_ip_addresses
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowIntraVaultSubnet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.vault_subnet_cidr
    destination_address_prefix = local.vault_subnet_cidr
  }
}

resource "azurerm_network_security_group" "core_nsg" {
  name                = "${var.project_name}-core-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.servers_rg.name
  tags                = local.common_tags

  security_rule {
    name                       = "AllowSSHFromAdmin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.admin_ip_addresses
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowIntraCoreSubnet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.core_subnet_cidr
    destination_address_prefix = local.core_subnet_cidr
  }
}

resource "azurerm_subnet_network_security_group_association" "vault_assoc" {
  subnet_id                 = azurerm_subnet.vault_subnet.id
  network_security_group_id = azurerm_network_security_group.vault_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "core_assoc" {
  subnet_id                 = azurerm_subnet.core_subnet.id
  network_security_group_id = azurerm_network_security_group.core_nsg.id
}

# ==============================================================================
# CLIENT NETWORKING (one VNet per DC, one subnet per VNet)
# ==============================================================================

resource "azurerm_virtual_network" "client_vnets" {
  for_each            = var.datacenters
  name                = "${var.project_name}-${each.key}-vnet"
  address_space       = [each.value.vnet_cidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.clients_rgs[each.key].name
  tags                = local.common_tags
}

resource "azurerm_subnet" "client_subnets" {
  for_each             = local.client_subnets
  name                 = "client-${each.key}-subnet"
  resource_group_name  = azurerm_resource_group.clients_rgs[each.key].name
  virtual_network_name = azurerm_virtual_network.client_vnets[each.key].name
  address_prefixes     = [each.value.cidr]
}

resource "azurerm_network_security_group" "client_nsgs" {
  for_each            = var.datacenters
  name                = "${var.project_name}-${each.key}-client-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.clients_rgs[each.key].name
  tags                = local.common_tags

  # Minimal: allow outbound to core subnet (tighten later to needed ports)
  security_rule {
    name                       = "AllowOutboundToCore"
    priority                   = 300
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = local.core_subnet_cidr
  }
}

resource "azurerm_subnet_network_security_group_association" "client_assoc" {
  for_each                  = azurerm_subnet.client_subnets
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.client_nsgs[each.key].id
}

# ==============================================================================
# PEERING: Server VNet <-> Client VNets
# ==============================================================================

resource "azurerm_virtual_network_peering" "server_to_clients" {
  for_each                     = var.enable_vnet_peering ? azurerm_virtual_network.client_vnets : {}
  name                         = "peer-servers-to-${each.key}"
  resource_group_name          = azurerm_resource_group.servers_rg.name
  virtual_network_name         = azurerm_virtual_network.server_vnet.name
  remote_virtual_network_id    = each.value.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "clients_to_server" {
  for_each                     = var.enable_vnet_peering ? azurerm_virtual_network.client_vnets : {}
  name                         = "peer-${each.key}-to-servers"
  resource_group_name          = azurerm_resource_group.clients_rgs[each.key].name
  virtual_network_name         = each.value.name
  remote_virtual_network_id    = azurerm_virtual_network.server_vnet.id
  allow_virtual_network_access = true
}

# ==============================================================================
# MANAGED IDENTITIES + KEY VAULT (software-protected key)
# ==============================================================================

resource "azurerm_user_assigned_identity" "vault_identity" {
  name                = "${var.project_name}-vault-mi"
  location            = var.location
  resource_group_name = azurerm_resource_group.servers_rg.name
  tags                = local.common_tags
}

resource "azurerm_user_assigned_identity" "core_identity" {
  name                = "${var.project_name}-core-mi"
  location            = var.location
  resource_group_name = azurerm_resource_group.servers_rg.name
  tags                = local.common_tags
}

resource "azurerm_key_vault" "unseal_kv" {
  name                          = "${var.kv_name}-${random_string.unique.id}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.servers_rg.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard" # software
  purge_protection_enabled      = true
  soft_delete_retention_days    = 30
  public_network_access_enabled = true

  tags = local.common_tags
}

# Access policy for operator (current principal)
resource "azurerm_key_vault_access_policy" "operator_ap" {
  key_vault_id = azurerm_key_vault.unseal_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore",
    "UnwrapKey", "WrapKey", "Verify", "Sign", "Purge", "GetRotationPolicy", "SetRotationPolicy"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
  ]
}

# Access policy for Vault MI (auto-unseal needs get/unwrap)
resource "azurerm_key_vault_access_policy" "vault_mi_ap" {
  key_vault_id = azurerm_key_vault.unseal_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.vault_identity.principal_id

  key_permissions = ["Get", "List", "WrapKey", "UnwrapKey"]
}

resource "time_sleep" "kv_ap_delay" {
  depends_on = [
    azurerm_key_vault_access_policy.operator_ap,
    azurerm_key_vault_access_policy.vault_mi_ap
  ]
  create_duration = "20s" # increase to 30–45s if needed
}

resource "azurerm_key_vault_key" "unseal_key" {
  name         = var.kv_key_name
  key_vault_id = azurerm_key_vault.unseal_kv.id
  key_type     = "RSA"
  key_size     = 3072
  key_opts     = ["unwrapKey", "wrapKey", "encrypt", "decrypt"]
  tags         = local.common_tags

  depends_on = [time_sleep.kv_ap_delay]
}

# ==============================================================================
# VM SCALE SETS (INFRA ONLY) + OPTIONAL INTERNAL LBs
# ==============================================================================



# ==============================================================================
# VAULT VMSS
# ==============================================================================


locals {
  vault_ilb_ip = (
    var.enable_vault_ilb
    ? try(azurerm_lb.vault_ilb[0].frontend_ip_configuration[0].private_ip_address, null)
    : null
  )

  vault_api_addr_value = (
    local.vault_ilb_ip != null
    ? format("http://%s:8200", local.vault_ilb_ip)
    : ""
  )

  vault_cluster_addr_value = ""

  vault_cloudinit_rendered = templatefile("${path.module}/vault-cloudinit.yaml.tmpl", {
    vault_version      = var.vault_version
    tenant_id          = data.azurerm_client_config.current.tenant_id
    kv_name            = azurerm_key_vault.unseal_kv.name
    kv_key_name        = var.kv_key_name
    vault_api_addr     = local.vault_api_addr_value
    vault_cluster_addr = local.vault_cluster_addr_value
    vault_tls_disable  = var.vault_tls_disable
  })

  vault_cloudinit_b64 = base64encode(local.vault_cloudinit_rendered)
}


# Vault VMSS
resource "azurerm_lb" "vault_ilb" {
  count               = var.enable_vault_ilb ? 1 : 0
  name                = "${var.project_name}-vault-ilb"
  location            = var.location
  resource_group_name = azurerm_resource_group.servers_rg.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                          = "vault-fe"
    subnet_id                     = azurerm_subnet.vault_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = local.common_tags
}

resource "azurerm_lb_backend_address_pool" "vault_pool" {
  count           = var.enable_vault_ilb ? 1 : 0
  loadbalancer_id = azurerm_lb.vault_ilb[0].id
  name            = "vault-bep"
}

resource "azurerm_lb_probe" "vault_probe" {
  count           = var.enable_vault_ilb ? 1 : 0
  loadbalancer_id = azurerm_lb.vault_ilb[0].id
  name            = "vault-8200"
  port            = 8200
  protocol        = "Tcp"
}

resource "azurerm_lb_rule" "vault_rule" {
  count                          = var.enable_vault_ilb ? 1 : 0
  loadbalancer_id                = azurerm_lb.vault_ilb[0].id
  name                           = "vault-8200"
  protocol                       = "Tcp"
  frontend_port                  = 8200
  backend_port                   = 8200
  frontend_ip_configuration_name = "vault-fe"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.vault_pool[0].id]
  probe_id                       = azurerm_lb_probe.vault_probe[0].id
}

resource "azurerm_linux_virtual_machine_scale_set" "vault_vmss" {
  name                = "${var.project_name}-vault-vmss"
  location            = var.location
  resource_group_name = azurerm_resource_group.servers_rg.name
  sku                 = var.vault_vm_size
  instances           = var.vault_instance_count

  zones = var.vault_zones

  source_image_reference {
    publisher = var.vault_image.publisher
    offer     = var.vault_image.offer
    sku       = var.vault_image.sku
    version   = var.vault_image.version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.vault_os_disk_type
    disk_size_gb         = var.vault_os_disk_size_gb
  }

  network_interface {
    name    = "vault-nic"
    primary = true

    ip_configuration {
      name                                   = "vault-ipcfg"
      primary                                = true
      subnet_id                              = azurerm_subnet.vault_subnet.id
      load_balancer_backend_address_pool_ids = var.enable_vault_ilb ? [azurerm_lb_backend_address_pool.vault_pool[0].id] : []
    }
  }

  admin_username = var.vm_admin_username

  # Authentication
  disable_password_authentication = var.enable_password_auth ? false : true
  admin_password                  = var.enable_password_auth ? var.vm_admin_password : null

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.admin_ssh_public_key
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vault_identity.id]
  }

  # Placeholder for later cloud-init (base64) if needed
  custom_data = local.vault_cloudinit_b64

  upgrade_mode = var.vault_upgrade_mode
  tags         = local.common_tags
}

# Public IP for NAT
resource "azurerm_public_ip" "nat_pip" {
  name                = "${var.project_name}-nat-pip"
  resource_group_name = azurerm_resource_group.servers_rg.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# NAT Gateway
resource "azurerm_nat_gateway" "nat_gw" {
  name                = "${var.project_name}-nat-gw"
  resource_group_name = azurerm_resource_group.servers_rg.name
  location            = var.location
  sku_name            = "Standard"
  tags                = local.common_tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gw_pip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_pip.id
}

# Associate NAT GW to Vault and Core subnets
resource "azurerm_subnet_nat_gateway_association" "vault_subnet_nat_assoc" {
  subnet_id      = azurerm_subnet.vault_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}

resource "azurerm_subnet_nat_gateway_association" "core_subnet_nat_assoc" {
  subnet_id      = azurerm_subnet.core_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}

# ==============================================================================
# core VMSS
# ==============================================================================

# Derive Core ILB address (optional)
locals {
  core_ilb_ip = (
    var.enable_core_ilb
    ? try(azurerm_lb.core_ilb[0].frontend_ip_configuration[0].private_ip_address, null)
    : null
  )

  consul_http_advertise = (
    local.core_ilb_ip != null
    ? format("http://%s:8500", local.core_ilb_ip)
    : ""
  )

  nomad_http_advertise = (
    local.core_ilb_ip != null
    ? format("%s", local.core_ilb_ip)
    : ""
  )

  # ILB-based retry join (static; all servers join via ILB VIP)
  consul_retry_join_json = jsonencode(
    local.core_ilb_ip != null ? [local.core_ilb_ip] : []
  )
}

# ==============================================================================
# Internal Load Balancer for Consul/Nomad
# ==============================================================================

resource "azurerm_lb" "core_ilb" {
  count               = var.enable_core_ilb ? 1 : 0
  name                = "${var.project_name}-core-ilb"
  location            = var.location
  resource_group_name = azurerm_resource_group.servers_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "core-fe"
    subnet_id                     = azurerm_subnet.core_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.common_tags
}

resource "azurerm_lb_backend_address_pool" "core_pool" {
  count           = var.enable_core_ilb ? 1 : 0
  loadbalancer_id = azurerm_lb.core_ilb[0].id
  name            = "core-bep"
}

resource "azurerm_lb_probe" "consul_probe" {
  count           = var.enable_core_ilb ? 1 : 0
  loadbalancer_id = azurerm_lb.core_ilb[0].id
  name            = "consul-8500"
  port            = 8500
  protocol        = "Tcp"
}

resource "azurerm_lb_rule" "consul_rule" {
  count                          = var.enable_core_ilb ? 1 : 0
  loadbalancer_id                = azurerm_lb.core_ilb[0].id
  name                           = "consul-8500"
  protocol                       = "Tcp"
  frontend_port                  = 8500
  backend_port                   = 8500
  frontend_ip_configuration_name = "core-fe"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.core_pool[0].id]
  probe_id                       = azurerm_lb_probe.consul_probe[0].id
}

# ==============================================================================
# Core VMSS
# ==============================================================================

# Generate cloud-init before VMSS creation (no dependency cycle)
locals {
  cloud_init_content = templatefile("${path.module}/core-cloudinit.yaml.tmpl", {
    consul_version         = var.consul_version
    nomad_version          = var.nomad_version
    consul_server          = true
    nomad_server_enabled   = true
    nomad_bootstrap_expect = var.core_instance_count
    consul_retry_join_json = local.consul_retry_join_json
    consul_http_advertise  = local.consul_http_advertise
  })

  core_cloudinit_b64 = base64encode(local.cloud_init_content)
}

resource "azurerm_linux_virtual_machine_scale_set" "core_vmss" {
  name                = "${var.project_name}-core-vmss"
  location            = var.location
  resource_group_name = azurerm_resource_group.servers_rg.name
  sku                 = var.core_vm_size
  instances           = var.core_instance_count
  zones               = var.core_zones

  source_image_reference {
    publisher = var.core_image.publisher
    offer     = var.core_image.offer
    sku       = var.core_image.sku
    version   = var.core_image.version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.core_os_disk_type
    disk_size_gb         = var.core_os_disk_size_gb
  }

  network_interface {
    name    = "core-nic"
    primary = true

    ip_configuration {
      name                                   = "core-ipcfg"
      primary                                = true
      subnet_id                              = azurerm_subnet.core_subnet.id
      load_balancer_backend_address_pool_ids = var.enable_core_ilb ? [azurerm_lb_backend_address_pool.core_pool[0].id] : []
    }
  }

  admin_username                  = var.vm_admin_username
  disable_password_authentication = var.enable_password_auth ? false : true
  admin_password                  = var.enable_password_auth ? var.vm_admin_password : null

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.admin_ssh_public_key
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.core_identity.id]
  }

  # Cloud-init runs automatically
  custom_data = local.core_cloudinit_b64

  upgrade_mode = var.core_upgrade_mode
  tags = merge(local.common_tags, {
    "consul-cluster" = "true"
  })

  depends_on = [
    azurerm_lb.core_ilb
  ]
}

# ==============================================================================
# CLIENT WORKLOAD VMSS (one per datacenter, infra-only by default)
# ==============================================================================

resource "azurerm_linux_virtual_machine_scale_set" "clients_vmss" {
  for_each            = var.datacenters
  name                = "${var.project_name}-${each.key}-clients-vmss"
  location            = var.location
  resource_group_name = azurerm_resource_group.clients_rgs[each.key].name
  sku                 = var.clients_vm_size
  instances           = var.clients_instance_count

  zones = var.clients_zones

  source_image_reference {
    publisher = var.clients_image.publisher
    offer     = var.clients_image.offer
    sku       = var.clients_image.sku
    version   = var.clients_image.version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.clients_os_disk_type
    disk_size_gb         = var.clients_os_disk_size_gb
  }

  network_interface {
    name    = "${var.project_name}-${each.key}-clients-nic"
    primary = true

    ip_configuration {
      name      = "${var.project_name}-${each.key}-clients-ipcfg"
      primary   = true
      subnet_id = azurerm_subnet.client_subnets[each.key].id
      # No LB by default; add backend pool IDs here if you later introduce ILBs for clients.
    }
  }

  admin_username = var.vm_admin_username

  disable_password_authentication = var.enable_password_auth ? false : true
  admin_password                  = var.enable_password_auth ? var.vm_admin_password : null

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.admin_ssh_public_key
  }

  identity {
    type = "SystemAssigned"
  }

  custom_data = var.clients_custom_data_base64

  upgrade_mode = var.clients_upgrade_mode
  tags         = local.common_tags
}


# ==============================================================================
# Jump Host (Public IP + NSG + NIC + VM)
# ==============================================================================

# Choose subnet based on var.jump_host_subnet
locals {
  jump_host_subnet_id = var.jump_host_subnet == "vault" ? azurerm_subnet.vault_subnet.id : azurerm_subnet.core_subnet.id
}

resource "azurerm_public_ip" "jump_pip" {
  count               = var.enable_jump_host ? 1 : 0
  name                = "${var.project_name}-jump-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.servers_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_network_security_group" "jump_nsg" {
  count               = var.enable_jump_host ? 1 : 0
  name                = "${var.project_name}-jump-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.servers_rg.name
  tags                = local.common_tags

  security_rule {
    name                       = "AllowSSHFromAdmin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.admin_ip_addresses
    destination_address_prefix = "*"
  }

  # Optional: block all other inbound (Standard NSG default deny already applies)
}

resource "azurerm_network_interface" "jump_nic" {
  count               = var.enable_jump_host ? 1 : 0
  name                = "${var.project_name}-jump-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.servers_rg.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = local.jump_host_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jump_pip[0].id
  }
}

resource "azurerm_network_interface_security_group_association" "jump_nic_nsg_assoc" {
  count                     = var.enable_jump_host ? 1 : 0
  network_interface_id      = azurerm_network_interface.jump_nic[0].id
  network_security_group_id = azurerm_network_security_group.jump_nsg[0].id
}

resource "azurerm_linux_virtual_machine" "jump_vm" {
  count                           = var.enable_jump_host ? 1 : 0
  name                            = "${var.project_name}-jump-vm"
  resource_group_name             = azurerm_resource_group.servers_rg.name
  location                        = var.location
  size                            = var.jump_host_vm_size
  admin_username                  = var.vm_admin_username
  network_interface_ids           = [azurerm_network_interface.jump_nic[0].id]
  disable_password_authentication = true
  tags                            = local.common_tags

  os_disk {
    name                 = "${var.project_name}-jump-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.jump_host_os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.jump_host_ssh_public_key
  }

  # Optional: small hardening and tooling via cloud-init
  custom_data = base64encode(<<-CLOUDINIT
    #cloud-config
    package_update: true
    packages:
      - htop
      - jq
      - unzip
      - net-tools
      - tcpdump
    runcmd:
      - sysctl -w net.ipv4.ip_forward=1
  CLOUDINIT
  )
}