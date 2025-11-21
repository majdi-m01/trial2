# Define regular outputs for command-line viewing
output "vault_rg_name" {
  value = azurerm_resource_group.vault_rg.name
}
output "vault_vnet_id" {
  value = azurerm_virtual_network.vault_vnet.id
}
output "vault_vnet_name" {
  value = azurerm_virtual_network.vault_vnet.name
}
output "location" {
  value = var.location
}
output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

# Generate a .tfvars.json file directly inside the next phase's infra directory
resource "local_file" "shared_outputs" {
  content = jsonencode({
    # Outputs for Phase 2
    location        = var.location
    vault_rg_name   = azurerm_resource_group.vault_rg.name
    vault_vnet_id   = azurerm_virtual_network.vault_vnet.id
    vault_vnet_name = azurerm_virtual_network.vault_vnet.name
  })
  # Corrected path: Go up from /infra, up from /01-vault-foundation, then down into the target
  filename = "${path.module}/../../02-nomad-consul/infra/shared_outputs.auto.tfvars.json"

  depends_on = [
    azurerm_resource_group.vault_rg,
    azurerm_virtual_network.vault_vnet
  ]
}