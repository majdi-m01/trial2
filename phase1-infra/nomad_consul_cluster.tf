# Resource Group and VNet
resource "azurerm_resource_group" "nomad_consul_rg" {
  name     = var.nomad_consul_rg_name
  location = var.location

  tags = var.tags
}

resource "azurerm_virtual_network" "nomad_consul_vnet" {
  name                = var.nomad_consul_vnet_name
  address_space       = var.nomad_consul_vnet_address_space
  location            = azurerm_resource_group.nomad_consul_rg.location
  resource_group_name = azurerm_resource_group.nomad_consul_rg.name

  tags = var.tags
}

resource "azurerm_subnet" "nomad_consul_subnet" {
  name                 = var.nomad_consul_subnet_name
  resource_group_name  = azurerm_resource_group.nomad_consul_rg.name
  virtual_network_name = azurerm_virtual_network.nomad_consul_vnet.name
  address_prefixes     = [var.nomad_consul_subnet_address_prefix]
}

# NSG for Nomad/Consul (SSH, Consul ports 8300-8600, Nomad 4646, allow from Vault and Clients)
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
    source_address_prefix      = var.ssh_allowed_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Consul-Server"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8301-8302"
    source_address_prefix      = "*" # From other clusters via peering
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Consul-Client"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8500-8501"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Nomad-Server"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4646-4648"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nomad_consul_subnet_nsg" {
  subnet_id                 = azurerm_subnet.nomad_consul_subnet.id
  network_security_group_id = azurerm_network_security_group.nomad_consul_nsg.id
}

# Internal LB for Nomad/Consul (HA mode for Nomad API/UI)
resource "azurerm_lb" "nomad_consul_lb" {
  count               = var.nomad_consul_instance_count > 1 ? 1 : 0
  name                = "lb-nomad-internal"
  location            = azurerm_resource_group.nomad_consul_rg.location
  resource_group_name = azurerm_resource_group.nomad_consul_rg.name

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
  name            = "backend-nomad"
}

resource "azurerm_lb_probe" "nomad_probe" {
  count           = var.nomad_consul_instance_count > 1 ? 1 : 0
  loadbalancer_id = azurerm_lb.nomad_consul_lb[0].id
  name            = "tcp-probe"
  port            = var.nomad_lb_port
  protocol        = "Tcp"
}

resource "azurerm_lb_rule" "nomad_rule" {
  count                          = var.nomad_consul_instance_count > 1 ? 1 : 0
  loadbalancer_id                = azurerm_lb.nomad_consul_lb[0].id
  name                           = "nomad-rule"
  protocol                       = "Tcp"
  frontend_port                  = var.nomad_lb_port
  backend_port                   = var.nomad_lb_port
  frontend_ip_configuration_name = "internal"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.nomad_consul_backend[0].id]
  probe_id                       = azurerm_lb_probe.nomad_probe[0].id
}

# VMSS for Nomad/Consul (clean image, no extensions)
resource "azurerm_linux_virtual_machine_scale_set" "nomad_consul_vmss" {
  name                = "vmss-nomad-consul"
  location            = azurerm_resource_group.nomad_consul_rg.location
  resource_group_name = azurerm_resource_group.nomad_consul_rg.name
  sku                 = var.nomad_consul_vm_size
  instances           = var.nomad_consul_instance_count
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  overprovision       = false

  source_image_reference {
    publisher = var.nomad_consul_image_publisher
    offer     = var.nomad_consul_image_offer
    sku       = var.nomad_consul_image_sku
    version   = var.nomad_consul_image_version
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
      subnet_id                              = azurerm_subnet.nomad_consul_subnet.id
      load_balancer_backend_address_pool_ids = var.nomad_consul_instance_count > 1 ? [azurerm_lb_backend_address_pool.nomad_consul_backend[0].id] : []

      public_ip_address { # ← changed block name
        name                    = "public-ip"
        idle_timeout_in_minutes = 30
      }
    }
  }

  disable_password_authentication = false

  tags = var.tags
}