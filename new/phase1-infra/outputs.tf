output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "vault_unseal_key_id" {
  description = "ID of the Key Vault key for Vault auto-unseal"
  value       = azurerm_key_vault_key.vault_unseal_key.id
}

output "vault_vmss_id" {
  description = "ID of the Vault VMSS"
  value       = azurerm_linux_virtual_machine_scale_set.vault_vmss.id
}

output "vault_lb_id" {
  description = "ID of the Vault LB (if created)"
  value       = var.vault_instance_count > 1 ? azurerm_lb.vault_lb[0].id : null
}

output "nomad_consul_vmss_id" {
  description = "ID of the Nomad/Consul VMSS"
  value       = azurerm_linux_virtual_machine_scale_set.nomad_consul_vmss.id
}

output "nomad_consul_lb_id" {
  description = "ID of the Nomad/Consul LB (if created)"
  value       = var.nomad_consul_instance_count > 1 ? azurerm_lb.nomad_consul_lb[0].id : null
}

output "datacenter_vmss_ids" {
  description = "IDs of Data Center VMSS"
  value       = { for k, v in azurerm_linux_virtual_machine_scale_set.datacenter_vmss : k => v.id }
}

output "datacenter_lb_ids" {
  description = "IDs of Data Center LBs (if created)"
  value       = { for k, v in azurerm_lb.datacenter_lb : k => v.id }
}

output "resource_groups" {
  description = "Names of all Resource Groups"
  value = {
    keyvault     = azurerm_resource_group.keyvault_rg.name
    vault        = azurerm_resource_group.vault_rg.name
    nomad_consul = azurerm_resource_group.nomad_consul_rg.name
    clients      = azurerm_resource_group.clients_rg.name
  }
}