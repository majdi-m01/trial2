# Read the shared variables file from the current directory
data "local_file" "existing_outputs" {
  filename = "${path.module}/shared_outputs.auto.tfvars.json"
}

# Define regular outputs for command-line viewing
output "nomad_consul_rg_name" {
  value = azurerm_resource_group.nomad_consul_rg.name
}
output "nomad_consul_vnet_id" {
  value = azurerm_virtual_network.nomad_consul_vnet.id
}

# Merge outputs and write the result directly into the next phase's infra directory
resource "local_file" "shared_outputs" {
  content = jsonencode(merge(
    can(jsondecode(data.local_file.existing_outputs.content)) ? jsondecode(data.local_file.existing_outputs.content) : {},
    {
      # Add new outputs for Phase 3
      nomad_consul_rg_name            = azurerm_resource_group.nomad_consul_rg.name
      nomad_consul_vnet_id            = azurerm_virtual_network.nomad_consul_vnet.id
      nomad_consul_vnet_name          = azurerm_virtual_network.nomad_consul_vnet.name,
      nomad_consul_vnet_address_space = var.nomad_consul_vnet_address_space,
      nomad_consul_lb_private_ip      = var.nomad_consul_lb_private_ip
    }
  ))
  # Corrected path for Phase 3
  filename = "${path.module}/../../03-client-datacenters/infra/shared_outputs.auto.tfvars.json"

  depends_on = [
    azurerm_resource_group.nomad_consul_rg,
    azurerm_virtual_network.nomad_consul_vnet
  ]
}