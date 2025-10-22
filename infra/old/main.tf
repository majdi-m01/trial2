# ==============================================================================
# PROVIDERS AND DATA SOURCES
# ==============================================================================

provider "azurerm" {
  features {}
  subscription_id = "f8cea8db-c84b-44eb-aa67-f8c938abbfda"
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
  create_vault_lb        = var.vault_server_count > 1
  create_nomad_consul_lb = var.nomad_consul_server_count > 1
  vault_servers          = { for i in range(var.vault_server_count) : "vault-server-${i}" => {} }
  nomad_consul_servers   = { for i in range(var.nomad_consul_server_count) : "nc-server-${i}" => {} }
  all_clients_map = { for client in flatten([
    for dc_key, dc_val in var.datacenters : [
      for i in range(dc_val.client_count) : {
        client_id = "${dc_key}-client-${i}"
        dc_key    = dc_key
      }
    ]
    ]) : client.client_id => client
  }
}

# ==============================================================================
# SHARED RESOURCES AND SERVER NETWORKING
# ==============================================================================

resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-servers-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "server_vnet" {
  name                = "${var.project_name}-server-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "vault_subnet" {
  name                 = "vault-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.server_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "nomad_consul_subnet" {
  name                 = "nomad-consul-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.server_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# ==============================================================================
# SERVER NETWORKING SECURITY
# ==============================================================================

resource "azurerm_network_security_group" "server_nsg" {
  name                = "${var.project_name}-server-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  # This rule for SSH already exists.
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

  # This rule for external API access already exists.
  security_rule {
    name                       = "AllowAPIsFromAdmin"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8500", "4646", "8200"]
    source_address_prefixes    = var.admin_ip_addresses
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowInternalServerComms"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = tolist(azurerm_virtual_network.server_vnet.address_space)[0]
    destination_address_prefix = tolist(azurerm_virtual_network.server_vnet.address_space)[0]
  }
}

resource "azurerm_subnet_network_security_group_association" "vault_nsg_assoc" {
  subnet_id                 = azurerm_subnet.vault_subnet.id
  network_security_group_id = azurerm_network_security_group.server_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nomad_consul_nsg_assoc" {
  subnet_id                 = azurerm_subnet.nomad_consul_subnet.id
  network_security_group_id = azurerm_network_security_group.server_nsg.id
}


# ==============================================================================
# SECURITY: AZURE KEY VAULT FOR VAULT AUTO-UNSEAL
# ==============================================================================

resource "azurerm_user_assigned_identity" "vault_identity" {
  name                = "${var.project_name}-vault-identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_key_vault" "unseal_kv" {
  name                        = "${var.project_name}-kv-${random_string.unique.id}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enabled_for_disk_encryption = true
  tags                        = var.tags

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "UnwrapKey", "WrapKey", "Verify", "Sign", "Purge",
      "GetRotationPolicy", "SetRotationPolicy"
    ]
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.vault_identity.principal_id

    key_permissions = [
      "Get", "Create", "Delete", "List", "WrapKey", "UnwrapKey", "Recover", "Sign", "Verify"
    ]
  }
}

resource "azurerm_key_vault_key" "unseal_key" {
  name         = "${var.project_name}-vault-unseal-key"
  key_vault_id = azurerm_key_vault.unseal_kv.id
  key_type     = "RSA"
  key_size     = 4096
  key_opts     = ["unwrapKey", "wrapKey", "sign", "verify"]
  tags         = var.tags
}

# ==============================================================================
# CLUSTER 1: VAULT SERVERS
# ==============================================================================

resource "azurerm_public_ip" "vault_lb_pip" {
  count               = local.create_vault_lb ? 1 : 0
  name                = "${var.project_name}-vault-lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_lb" "vault_lb" {
  count               = local.create_vault_lb ? 1 : 0
  name                = "${var.project_name}-vault-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = var.tags
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.vault_lb_pip[0].id
  }
}

resource "azurerm_lb_backend_address_pool" "vault_pool" {
  count           = local.create_vault_lb ? 1 : 0
  loadbalancer_id = azurerm_lb.vault_lb[0].id
  name            = "VaultBackendPool"
}

resource "azurerm_lb_probe" "vault_probe" {
  count           = local.create_vault_lb ? 1 : 0
  loadbalancer_id = azurerm_lb.vault_lb[0].id
  name            = "vault-health-probe"
  port            = 8200
  protocol        = "Http"
  request_path    = "/v1/sys/health"
}

resource "azurerm_lb_rule" "vault_rule" {
  count                          = local.create_vault_lb ? 1 : 0
  loadbalancer_id                = azurerm_lb.vault_lb[0].id
  name                           = "vault-rule"
  protocol                       = "Tcp"
  frontend_port                  = 8200
  backend_port                   = 8200
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.vault_pool[0].id]
  probe_id                       = azurerm_lb_probe.vault_probe[0].id
}

resource "azurerm_public_ip" "single_vault_pip" {
  count               = !local.create_vault_lb ? 1 : 0
  name                = "${var.project_name}-vault-server-0-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "vault_nic" {
  for_each            = local.vault_servers
  name                = "${var.project_name}-${each.key}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vault_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = !local.create_vault_lb && each.key == "vault-server-0" ? azurerm_public_ip.single_vault_pip[0].id : null
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "vault_nic_pool_assoc" {
  for_each                = local.create_vault_lb ? local.vault_servers : {}
  network_interface_id    = azurerm_network_interface.vault_nic[each.key].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.vault_pool[0].id
}

resource "azurerm_linux_virtual_machine" "vault_vm" {
  for_each = local.vault_servers
  timeouts {
    create = "60m"
    delete = "60m"
  }
  name                            = "${var.project_name}-${each.key}"
  computer_name                   = each.key
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B2s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.vault_nic[each.key].id]
  tags                            = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vault_identity.id]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/vault_server_init.yml.tpl", {
    node_name         = each.key
    private_ip        = azurerm_network_interface.vault_nic[each.key].private_ip_address
    leader_private_ip = azurerm_network_interface.vault_nic["vault-server-0"].private_ip_address
    access_public_ip  = local.create_vault_lb ? azurerm_public_ip.vault_lb_pip[0].ip_address : azurerm_public_ip.single_vault_pip[0].ip_address
    tenant_id         = data.azurerm_client_config.current.tenant_id
    key_vault_name    = azurerm_key_vault.unseal_kv.name
    key_name          = azurerm_key_vault_key.unseal_key.name
  }))
}

# ==============================================================================
# CLUSTER 2: NOMAD & CONSUL SERVERS
# ==============================================================================

resource "azurerm_public_ip" "nc_lb_pip" {
  count               = local.create_nomad_consul_lb ? 1 : 0
  name                = "${var.project_name}-nc-lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_lb" "nc_lb" {
  count               = local.create_nomad_consul_lb ? 1 : 0
  name                = "${var.project_name}-nc-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = var.tags
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.nc_lb_pip[0].id
  }
}

resource "azurerm_lb_backend_address_pool" "nc_pool" {
  count           = local.create_nomad_consul_lb ? 1 : 0
  loadbalancer_id = azurerm_lb.nc_lb[0].id
  name            = "NBackendPool"
}

resource "azurerm_lb_rule" "nomad_rule" {
  count                          = local.create_nomad_consul_lb ? 1 : 0
  loadbalancer_id                = azurerm_lb.nc_lb[0].id
  name                           = "nomad-rule-4646"
  protocol                       = "Tcp"
  frontend_port                  = 4646
  backend_port                   = 4646
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.nc_pool[0].id]
}
resource "azurerm_lb_rule" "consul_rule" {
  count                          = local.create_nomad_consul_lb ? 1 : 0
  loadbalancer_id                = azurerm_lb.nc_lb[0].id
  name                           = "consul-rule-8500"
  protocol                       = "Tcp"
  frontend_port                  = 8500
  backend_port                   = 8500
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.nc_pool[0].id]
}

resource "azurerm_public_ip" "single_nc_pip" {
  count               = !local.create_nomad_consul_lb ? 1 : 0
  name                = "${var.project_name}-nc-server-0-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "nc_nic" {
  for_each            = local.nomad_consul_servers
  name                = "${var.project_name}-${each.key}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.nomad_consul_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = !local.create_nomad_consul_lb && each.key == "nc-server-0" ? azurerm_public_ip.single_nc_pip[0].id : null
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "nc_nic_pool_assoc" {
  for_each                = local.create_nomad_consul_lb ? local.nomad_consul_servers : {}
  network_interface_id    = azurerm_network_interface.nc_nic[each.key].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.nc_pool[0].id
}

resource "azurerm_linux_virtual_machine" "nc_vm" {
  for_each = local.nomad_consul_servers
  timeouts {
    create = "60m"
    delete = "60m"
  }
  name                            = "${var.project_name}-${each.key}"
  computer_name                   = each.key
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B2s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nc_nic[each.key].id]
  tags                            = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/nomad_consul_server_init.yml.tpl", {
    server_count      = var.nomad_consul_server_count
    private_ip        = azurerm_network_interface.nc_nic[each.key].private_ip_address
    consul_retry_join = jsonencode(values(azurerm_network_interface.nc_nic)[*].private_ip_address)
    vault_leader_ip   = azurerm_network_interface.vault_nic["vault-server-0"].private_ip_address
  }))
}

# ==============================================================================
# DYNAMIC CLIENT DATACENTERS
# ==============================================================================

resource "azurerm_resource_group" "client_rgs" {
  for_each = var.datacenters
  name     = "${var.project_name}-${each.key}-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "client_vnets" {
  for_each            = var.datacenters
  name                = "${var.project_name}-${each.key}-vnet"
  address_space       = [each.value.vnet_address_space]
  location            = var.location
  resource_group_name = azurerm_resource_group.client_rgs[each.key].name
  tags                = var.tags
}

resource "azurerm_subnet" "client_subnets" {
  for_each             = var.datacenters
  name                 = "${each.key}-subnet"
  resource_group_name  = azurerm_resource_group.client_rgs[each.key].name
  virtual_network_name = azurerm_virtual_network.client_vnets[each.key].name
  address_prefixes     = [cidrsubnet(each.value.vnet_address_space, 8, 1)]
}

resource "azurerm_virtual_network_peering" "server_to_clients" {
  for_each                  = azurerm_virtual_network.client_vnets
  name                      = "peer-servers-to-${each.key}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.server_vnet.name
  remote_virtual_network_id = each.value.id
}

resource "azurerm_virtual_network_peering" "clients_to_server" {
  for_each                  = azurerm_virtual_network.client_vnets
  name                      = "peer-${each.key}-to-servers"
  resource_group_name       = azurerm_resource_group.client_rgs[each.key].name
  virtual_network_name      = each.value.name
  remote_virtual_network_id = azurerm_virtual_network.server_vnet.id
}

resource "azurerm_network_interface" "client_nic" {
  for_each            = local.all_clients_map
  name                = "${var.project_name}-${each.key}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.client_rgs[each.value.dc_key].name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.client_subnets[each.value.dc_key].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "client_vm" {
  for_each = local.all_clients_map
  timeouts {
    create = "60m"
    delete = "60m"
  }
  name                            = "${var.project_name}-${each.key}"
  computer_name                   = each.key
  resource_group_name             = azurerm_resource_group.client_rgs[each.value.dc_key].name
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.client_nic[each.key].id]
  tags                            = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/client_cloud_init.yml.tpl", {
    private_ip        = azurerm_network_interface.client_nic[each.key].private_ip_address
    consul_retry_join = jsonencode(values(azurerm_network_interface.nc_nic)[*].private_ip_address)
    nomad_servers     = jsonencode(values(azurerm_network_interface.nc_nic)[*].private_ip_address)
  }))
}