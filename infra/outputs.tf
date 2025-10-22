# --- Vault Cluster Outputs ---

output "vault_access_public_ip" {
  description = "The public IP address for accessing the Vault cluster API and UI."
  value       = var.vault_server_count > 1 ? azurerm_public_ip.vault_lb_pip[0].ip_address : azurerm_public_ip.single_vault_pip[0].ip_address
}

output "vault_server_private_ips" {
  description = "The private IP addresses of the Vault server nodes."
  value       = { for key, nic in azurerm_network_interface.vault_nic : key => nic.private_ip_address }
}


# --- Nomad/Consul Cluster Outputs ---

output "nomad_consul_access_public_ip" {
  description = "The public IP address for accessing the Nomad and Consul cluster APIs and UIs."
  value       = var.nomad_consul_server_count > 1 ? azurerm_public_ip.nc_lb_pip[0].ip_address : azurerm_public_ip.single_nc_pip[0].ip_address
}

output "nomad_consul_server_private_ips" {
  description = "The private IP addresses of the Nomad/Consul server nodes."
  value       = { for key, nic in azurerm_network_interface.nc_nic : key => nic.private_ip_address }
}


# --- General Outputs ---

output "how_to_connect_to_vms" {
  description = "Instructions on how to connect to the server nodes."
  value       = "The server VMs do not have direct public SSH access for security. To connect, you must use a secure method like Azure Bastion, which can connect to the server VNet."
}