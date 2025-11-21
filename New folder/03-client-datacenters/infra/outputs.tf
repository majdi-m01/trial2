output "client_resource_group_name" {
  description = "Name of the Client Datacenters Resource Group"
  value       = azurerm_resource_group.clients_rg.name
}

output "client_vnet_name" {
  description = "Name of the Client Datacenters VNet"
  value       = azurerm_virtual_network.clients_vnet.name
}

output "datacenter_vmss_ids" {
  description = "IDs of the Data Center VM Scale Sets"
  value       = { for k, v in azurerm_linux_virtual_machine_scale_set.datacenter_vmss : k => v.id }
}