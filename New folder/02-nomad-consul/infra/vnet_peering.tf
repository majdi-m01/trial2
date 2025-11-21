# Peering between Vault and Nomad/Consul
resource "azurerm_virtual_network_peering" "vault_to_nomad" {
  count = var.enable_vnet_peering ? 1 : 0

  name                      = "peer-vault-to-nomad"
  resource_group_name       = var.vault_rg_name # From shared file
  virtual_network_name      = var.vault_vnet_name # From shared file
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
  remote_virtual_network_id = var.vault_vnet_id # From shared file

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}