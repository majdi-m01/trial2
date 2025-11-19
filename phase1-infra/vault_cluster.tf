# phase1-infra/vault_cluster.tf

locals {
  # api_addr → clients talk to LB (HA) or local IP (single node, via placeholder)
  vault_api_addr = var.vault_instance_count > 1 ? (
    "http://${var.vault_lb_private_ip}:8200"  # Use var to avoid count dependency issues
  ) : "http://LOCAL_IP:8200"

  # cluster_addr → ALWAYS node-local IP:port (via placeholder)
  vault_cluster_addr = "http://LOCAL_IP:8201"

  leader_api_addr = "http://${var.vault_lb_private_ip}:8200"

  vault_hcl = templatefile("${path.module}/cloud-init/vault.hcl.tpl", {
    leader_api_addr = local.leader_api_addr
    api_addr      = local.vault_api_addr
    cluster_addr  = local.vault_cluster_addr
    tenant_id     = data.azurerm_client_config.current.tenant_id
    key_vault_name = azurerm_key_vault.main.name
    key_name      = azurerm_key_vault_key.vault_unseal_key.name
    #resource_group_name = azurerm_resource_group.vault_rg.name
    subscription_id     = data.azurerm_client_config.current.subscription_id

  })

  vault_service = file("${path.module}/cloud-init/vault.service")
}

# Resource Group and VNet
resource "azurerm_resource_group" "vault_rg" {
  name     = var.vault_rg_name
  location = var.location

  tags = var.tags
}

resource "azurerm_virtual_network" "vault_vnet" {
  name                = var.vault_vnet_name
  address_space       = var.vault_vnet_address_space
  location            = azurerm_resource_group.vault_rg.location
  resource_group_name = azurerm_resource_group.vault_rg.name

  tags = var.tags
}

resource "azurerm_subnet" "vault_subnet" {
  name                 = var.vault_subnet_name
  resource_group_name  = azurerm_resource_group.vault_rg.name
  virtual_network_name = azurerm_virtual_network.vault_vnet.name
  address_prefixes     = [var.vault_subnet_address_prefix]
}

# NSG for Vault (allow SSH from allowed IP, Vault port 8200 internally, and from Key Vault)
resource "azurerm_network_security_group" "vault_nsg" {
  name                = "nsg-vault"
  location            = azurerm_resource_group.vault_rg.location
  resource_group_name = azurerm_resource_group.vault_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_allowed_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Vault-API"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8200"
    source_address_prefix      = "*" # Allow from other VNets via peering
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KeyVault-Access"
    priority                   = 1003
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureKeyVault"   # ← service tag
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "vault_subnet_nsg" {
  subnet_id                 = azurerm_subnet.vault_subnet.id
  network_security_group_id = azurerm_network_security_group.vault_nsg.id
}

# Internal LB for Vault (HA mode)
resource "azurerm_lb" "vault_lb" {
  count               = var.vault_instance_count > 1 ? 1 : 0
  name                = "lb-vault-internal"
  location            = azurerm_resource_group.vault_rg.location
  resource_group_name = azurerm_resource_group.vault_rg.name

  frontend_ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vault_subnet.id
    private_ip_address            = var.vault_lb_private_ip
    private_ip_address_allocation = "Static"
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "vault_backend" {
  count           = var.vault_instance_count > 1 ? 1 : 0
  loadbalancer_id = azurerm_lb.vault_lb[0].id
  name            = "backend-vault"
}

resource "azurerm_lb_probe" "vault_probe" {
  count           = var.vault_instance_count > 1 ? 1 : 0
  loadbalancer_id = azurerm_lb.vault_lb[0].id
  name            = "tcp-probe"
  port            = var.vault_lb_port
  protocol        = "Tcp"
}

resource "azurerm_lb_rule" "vault_rule" {
  count                          = var.vault_instance_count > 1 ? 1 : 0
  loadbalancer_id                = azurerm_lb.vault_lb[0].id
  name                           = "vault-rule"
  protocol                       = "Tcp"
  frontend_port                  = var.vault_lb_port
  backend_port                   = var.vault_lb_port
  frontend_ip_configuration_name = "internal"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.vault_backend[0].id]
  probe_id                       = azurerm_lb_probe.vault_probe[0].id
}

# VMSS for Vault with System Assigned Managed Identity for Key Vault access (clean image, no extensions)
resource "azurerm_linux_virtual_machine_scale_set" "vault_vmss" {
  name                = "vmss-vault"
  location            = azurerm_resource_group.vault_rg.location
  resource_group_name = azurerm_resource_group.vault_rg.name
  sku                 = var.vault_vm_size
  instances           = var.vault_instance_count
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  overprovision       = false

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = var.vault_image_publisher
    offer     = var.vault_image_offer
    sku       = var.vault_image_sku
    version   = var.vault_image_version
  }

  os_disk {
    storage_account_type = var.os_disk_type
    caching              = "ReadWrite"
    disk_size_gb         = var.os_disk_size_gb   # ← changed
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.vault_subnet.id
      load_balancer_backend_address_pool_ids = var.vault_instance_count > 1 ? [azurerm_lb_backend_address_pool.vault_backend[0].id] : []

      public_ip_address {                 
        name                    = "pip-vault"
        idle_timeout_in_minutes = 30
        domain_name_label       = "vault-${random_string.suffix.result}"
      }
    }
  }

  disable_password_authentication = false

  # === CLOUD-INIT: INJECT SEPARATE HCL FILES ===
  custom_data = base64encode(templatefile("${path.module}/cloud-init/user-data.yaml.tpl", {
    vault_hcl_content     = indent(6, local.vault_hcl)
    vault_service_content = indent(6, local.vault_service)  
  }))

  tags = merge(var.tags, {
    VaultCluster = "my-vault-cluster"   
  })
}

resource "azurerm_key_vault_access_policy" "vault_vmss_access" {

  key_vault_id = azurerm_key_vault.main.id 
  tenant_id    = data.azurerm_client_config.current.tenant_id

  # References the Managed Identity's Principal ID from the VMSS
  object_id    = azurerm_linux_virtual_machine_scale_set.vault_vmss.identity[0].principal_id

  # Required permissions for the Azure Key Vault Seal
  key_permissions = [
    "Get",         # For fetching the key
    "WrapKey",     # For sealing the root key
    "UnwrapKey"    # For unsealing the root key
  ]
}
