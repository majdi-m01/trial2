# Peering between Clients and Nomad/Consul
resource "azurerm_virtual_network_peering" "clients_to_nomad" {
  count = var.enable_vnet_peering ? 1 : 0

  name                      = "peer-clients-to-nomad"
  resource_group_name       = azurerm_resource_group.clients_rg.name
  virtual_network_name      = azurerm_virtual_network.clients_vnet.name
  remote_virtual_network_id = var.nomad_consul_vnet_id # From shared file

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "nomad_to_clients" {
  count = var.enable_vnet_peering ? 1 : 0

  name                      = "peer-nomad-to-clients"
  resource_group_name       = var.nomad_consul_rg_name # From shared file
  virtual_network_name      = var.nomad_consul_vnet_name # From shared file
  remote_virtual_network_id = azurerm_virtual_network.clients_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Peering between Clients and Vault
resource "azurerm_virtual_network_peering" "clients_to_vault" {
  count = var.enable_vnet_peering ? 1 : 0

  name                      = "peer-clients-to-vault"
  resource_group_name       = azurerm_resource_group.clients_rg.name
  virtual_network_name      = azurerm_virtual_network.clients_vnet.name
  remote_virtual_network_id = var.vault_vnet_id # From shared file

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "vault_to_clients" {
  count = var.enable_vnet_peering ? 1 : 0

  name                      = "peer-vault-to-clients"
  resource_group_name       = var.vault_rg_name # From shared file
  virtual_network_name      = var.vault_vnet_name # From shared file
  remote_virtual_network_id = azurerm_virtual_network.clients_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}