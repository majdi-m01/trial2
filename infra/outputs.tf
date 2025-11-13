# ==============================================================================
# Networking
# ==============================================================================

output "server_vnet_id" {
  description = "ID of the server VNet."
  value       = azurerm_virtual_network.server_vnet.id
}

output "vault_subnet_id" {
  description = "ID of the Vault subnet."
  value       = azurerm_subnet.vault_subnet.id
}

output "core_subnet_id" {
  description = "ID of the Consul/Nomad subnet."
  value       = azurerm_subnet.core_subnet.id
}

output "client_vnet_ids" {
  description = "Map of client VNet IDs by datacenter key."
  value       = { for k, v in azurerm_virtual_network.client_vnets : k => v.id }
}

output "client_subnet_ids" {
  description = "Map of client subnet IDs by datacenter key."
  value       = { for k, s in azurerm_subnet.client_subnets : k => s.id }
}

# ==============================================================================
# Key Vault
# ==============================================================================

output "key_vault_id" {
  description = "Key Vault ID used for Vault auto-unseal."
  value       = azurerm_key_vault.unseal_kv.id
}

output "key_vault_uri" {
  description = "Key Vault URI."
  value       = azurerm_key_vault.unseal_kv.vault_uri
}

output "unseal_key_id" {
  description = "Key ID of the software-protected unseal key."
  value       = azurerm_key_vault_key.unseal_key.id
}

# ==============================================================================
# VM Scale Sets
# ==============================================================================

output "vault_vmss_id" {
  description = "Resource ID of the Vault VMSS."
  value       = azurerm_linux_virtual_machine_scale_set.vault_vmss.id
}

output "core_vmss_id" {
  description = "Resource ID of the Consul/Nomad VMSS."
  value       = azurerm_linux_virtual_machine_scale_set.core_vmss.id
}

output "vault_ilb_ip" {
  description = "Private IP of the Vault internal Load Balancer (if enabled)."
  value       = try(azurerm_lb.vault_ilb[0].frontend_ip_configuration[0].private_ip_address, null)
}

output "core_ilb_ip" {
  description = "Private IP of the Core internal Load Balancer (if enabled)."
  value       = try(azurerm_lb.core_ilb[0].frontend_ip_configuration[0].private_ip_address, null)
}

output "clients_vmss_ids" {
  description = "Map of client VMSS IDs by datacenter key."
  value       = { for k, v in azurerm_linux_virtual_machine_scale_set.clients_vmss : k => v.id }
}

output "clients_vmss_names" {
  description = "Map of client VMSS names by datacenter key."
  value       = { for k, v in azurerm_linux_virtual_machine_scale_set.clients_vmss : k => v.name }
}

output "jump_host_public_ip" {
  description = "Public IP of the jump host (if enabled)."
  value       = try(azurerm_public_ip.jump_pip[0].ip_address, null)
}

output "jump_host_private_ip" {
  description = "Private IP of the jump host (if enabled)."
  value       = try(azurerm_network_interface.jump_nic[0].private_ip_address, null)
}

# ==============================================================================
# Guidance
# ==============================================================================

output "next_steps" {
  description = "Operator guidance after infra apply."
  value       = "Attach cloud-init (custom_data) to VMSS modules to install Vault (Raft + Key Vault auto-unseal), Consul, and Nomad. Initialize Vault exactly once offline; do not store tokens in state."
}

