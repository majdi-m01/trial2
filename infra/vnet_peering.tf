# phase1-infra/vnet_peering.tf
# Peering between Vault and Nomad/Consul
resource "azurerm_virtual_network_peering" "vault_to_nomad" {
  count = var.enable_vnet_peering ? 1 : 0

  name                      = "peer-vault-to-nomad"
  resource_group_name       = azurerm_resource_group.vault_rg.name
  virtual_network_name      = azurerm_virtual_network.vault_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.nomad_consul_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "nomad_to_vault" {
  count = var.enable_vnet_peering ? 1 : 0

  name                      = "peer-nomad-to-vault"
  resource_group_name       = azurerm_resource_group.nomad_consul_rg.name
  virtual_network_name      = azurerm_virtual_network.nomad_consul_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vault_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Peering between Nomad/Consul and Clients
resource "azurerm_virtual_network_peering" "nomad_to_clients" {
  count = var.enable_vnet_peering ? 1 : 0

  name                      = "peer-nomad-to-clients"
  resource_group_name       = azurerm_resource_group.nomad_consul_rg.name
  virtual_network_name      = azurerm_virtual_network.nomad_consul_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.clients_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "clients_to_nomad" {
  count = var.enable_vnet_peering ? 1 : 0

  name                      = "peer-clients-to-nomad"
  resource_group_name       = azurerm_resource_group.clients_rg.name
  virtual_network_name      = azurerm_virtual_network.clients_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.nomad_consul_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Peering between Vault and Clients
resource "azurerm_virtual_network_peering" "vault_to_clients" {
  count = var.enable_vnet_peering ? 1 : 0

  name                      = "peer-vault-to-clients"
  resource_group_name       = azurerm_resource_group.vault_rg.name
  virtual_network_name      = azurerm_virtual_network.vault_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.clients_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "clients_to_vault" {
  count = var.enable_vnet_peering ? 1 : 0

  name                      = "peer-clients-to-vault"
  resource_group_name       = azurerm_resource_group.clients_rg.name
  virtual_network_name      = azurerm_virtual_network.clients_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vault_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}