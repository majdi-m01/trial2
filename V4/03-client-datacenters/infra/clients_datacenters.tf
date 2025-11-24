locals {
  client_agent_user_data = base64encode(templatefile("${path.module}/../cloud-init-client-agents/user-data.yaml.tpl", {
    install_tools_content = indent(6, file("${path.module}/../cloud-init-client-agents/install-hashi-tools.sh"))
    consul_client_hcl     = indent(6, local.consul_client_hcl)
    nomad_client_hcl      = indent(6, local.nomad_client_hcl)
    consul_service        = indent(6, file("${path.module}/../cloud-init-client-agents/consul.service"))
    nomad_service         = indent(6, file("${path.module}/../cloud-init-client-agents/nomad.service"))
  }))

  consul_client_hcl = templatefile("${path.module}/../cloud-init-client-agents/consul-client.hcl.tpl", {
    datacenter          = var.location
    consul_server_lb_ip = var.nomad_consul_lb_private_ip
  })

  nomad_client_hcl = templatefile("${path.module}/../cloud-init-client-agents/nomad-client.hcl.tpl", {
    datacenter = var.location
  })
}

# Resource Group and VNet for the clients
resource "azurerm_resource_group" "clients_rg" {
  name     = var.clients_rg_name
  location = var.location # From shared file
  tags     = var.tags
}

resource "azurerm_virtual_network" "clients_vnet" {
  name                = var.clients_vnet_name
  address_space       = var.clients_vnet_address_space
  location            = azurerm_resource_group.clients_rg.location
  resource_group_name = azurerm_resource_group.clients_rg.name
  tags                = var.tags
}

locals {
  num_datacenters = length(keys(var.datacenter_configs))
  dc_keys         = keys(var.datacenter_configs)
  subnet_prefixes = length(var.datacenter_subnet_prefixes) == 0 ? [for i in range(local.num_datacenters) : "10.2.${i + 1}.0/24"] : var.datacenter_subnet_prefixes
  datacenters_ha  = { for k, v in var.datacenter_configs : k => v if v > 1 }
}

# Dynamic subnets for each Data Center
resource "azurerm_subnet" "datacenter_subnet" {
  for_each = var.datacenter_configs

  name                 = "snet-dc-${each.key}"
  resource_group_name  = azurerm_resource_group.clients_rg.name
  virtual_network_name = azurerm_virtual_network.clients_vnet.name
  address_prefixes     = [local.subnet_prefixes[index(local.dc_keys, each.key)]]
}

# NSG for Clients/Data Centers
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
    name                       = "AllowOutboundToConsulServers"
    priority                   = 2001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8301", "8500"] # Server RPC and API
    source_address_prefix      = "*"
    destination_address_prefix = var.nomad_consul_vnet_address_space[0]
  }

  security_rule {
    name                       = "AllowOutboundToNomadServers"
    priority                   = 2002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4646" # Nomad Server API
    source_address_prefix      = "*"
    destination_address_prefix = var.nomad_consul_vnet_address_space[0]
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "datacenter_subnet_nsg" {
  for_each = azurerm_subnet.datacenter_subnet

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.clients_nsg.id
}

# Dynamic VMSS for each Data Center
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
    disk_size_gb         = var.os_disk_size_gb
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.datacenter_subnet[each.key].id
    }
  }

  disable_password_authentication = false

  custom_data = local.client_agent_user_data

  tags = var.tags
}