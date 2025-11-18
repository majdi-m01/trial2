# Resource Group and VNet
resource "azurerm_resource_group" "clients_rg" {
  name     = var.clients_rg_name
  location = var.location

  tags = var.tags
}

resource "azurerm_virtual_network" "clients_vnet" {
  name                = var.clients_vnet_name
  address_space       = var.clients_vnet_address_space
  location            = azurerm_resource_group.clients_rg.location
  resource_group_name = azurerm_resource_group.clients_rg.name

  tags = var.tags
}

locals {
  num_datacenters = length(keys(var.datacenter_configs))
  subnet_prefixes = length(var.datacenter_subnet_prefixes) == 0 ? [for i in range(local.num_datacenters) : "10.2.${i + 1}.0/24"] : var.datacenter_subnet_prefixes
  datacenters_ha  = { for k, v in var.datacenter_configs : k => v if v > 1 }
}

# Dynamic subnets and VMSS for Data Centers
resource "azurerm_subnet" "datacenter_subnet" {
  for_each = { for idx, key in keys(var.datacenter_configs) : key => idx }

  name                 = "snet-dc-${each.key}"
  resource_group_name  = azurerm_resource_group.clients_rg.name
  virtual_network_name = azurerm_virtual_network.clients_vnet.name
  address_prefixes     = [local.subnet_prefixes[tonumber(each.value)]]
}

# NSG for Clients/Data Centers (SSH, allow to/from Nomad/Consul/Vault on Hashi ports)
resource "azurerm_network_security_group" "clients_nsg" {
  name                = "nsg-clients"
  location            = azurerm_resource_group.clients_rg.location
  resource_group_name = azurerm_resource_group.clients_rg.name

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
    name                       = "Hashi-ClientToVault"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8200"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Hashi-ClientToConsul"
    priority                   = 1003
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8300", "8301", "8302", "8500", "8501", "8600"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Hashi-ClientToNomad"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["4646", "4647", "4648"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow LB traffic
  security_rule {
    name                       = "LB-Ingress"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.datacenter_lb_port)
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "datacenter_subnet_nsg" {
  for_each = azurerm_subnet.datacenter_subnet

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.clients_nsg.id
}

# External Public LB for Data Centers (HA mode only when >1 instance)
resource "azurerm_public_ip" "datacenter_lb_pip" {
  for_each = local.datacenters_ha

  name                = "pip-lb-dc-${each.key}"
  location            = azurerm_resource_group.clients_rg.location
  resource_group_name = azurerm_resource_group.clients_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_lb" "datacenter_lb" {
  for_each = local.datacenters_ha

  name                = "lb-dc-${each.key}-external"
  location            = azurerm_resource_group.clients_rg.location
  resource_group_name = azurerm_resource_group.clients_rg.name

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.datacenter_lb_pip[each.key].id
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "datacenter_backend" {
  for_each = local.datacenters_ha

  loadbalancer_id = azurerm_lb.datacenter_lb[each.key].id
  name            = "backend-dc-${each.key}"
}

resource "azurerm_lb_probe" "datacenter_probe" {
  for_each = local.datacenters_ha

  loadbalancer_id = azurerm_lb.datacenter_lb[each.key].id
  name            = "tcp-probe"
  port            = var.datacenter_lb_port
  protocol        = "Tcp"
}

resource "azurerm_lb_rule" "datacenter_rule" {
  for_each = local.datacenters_ha

  loadbalancer_id                = azurerm_lb.datacenter_lb[each.key].id
  name                           = "dc-rule-${each.key}"
  protocol                       = "Tcp"
  frontend_port                  = var.datacenter_lb_port
  backend_port                   = var.datacenter_lb_port
  frontend_ip_configuration_name = "public"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.datacenter_backend[each.key].id]
  probe_id                       = azurerm_lb_probe.datacenter_probe[each.key].id
}

# Dynamic VMSS for each Data Center (clean image, no extensions)
resource "azurerm_linux_virtual_machine_scale_set" "datacenter_vmss" {
  for_each = var.datacenter_configs

  name                = "vmss-dc-${each.key}"
  location            = azurerm_resource_group.clients_rg.location
  resource_group_name = azurerm_resource_group.clients_rg.name
  sku                 = var.clients_vm_size
  instances           = each.value
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  overprovision       = false

  source_image_reference {
    publisher = var.clients_image_publisher
    offer     = var.clients_image_offer
    sku       = var.clients_image_sku
    version   = var.clients_image_version
  }

  os_disk {
    storage_account_type = var.os_disk_type
    caching              = "ReadWrite"
    disk_size_gb         = var.os_disk_size_gb # ← changed
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.datacenter_subnet[each.key].id
      load_balancer_backend_address_pool_ids = contains(keys(local.datacenters_ha), each.key) ? [azurerm_lb_backend_address_pool.datacenter_backend[each.key].id] : []

      public_ip_address { # ← changed block name
        name                    = "public-ip"
        idle_timeout_in_minutes = 30
      }
    }
  }

  disable_password_authentication = false

  tags = var.tags
}