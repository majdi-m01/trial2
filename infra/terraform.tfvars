# --------------------------------------------------------------------
# Example `infra/terraform.tfvars` for a Production-like Deployment
# --------------------------------------------------------------------

# --- Mandatory Secrets ---
admin_password     = "ChangeMeToA-Very-Strong-P@ssword!"
admin_ip_addresses = ["212.114.159.234", "88.64.185.12"]

# --- Core Settings ---
project_name = "hashicorp-demo"
location     = "West Europe"

# --- Server Sizing ---
vault_server_count        = 1
nomad_consul_server_count = 1

# --- Client Datacenter Layout ---
datacenters = {
  "primary-dc" = {
    vnet_address_space = "10.100.0.0/16"
    client_count       = 3
  },
  "secondary-dc" = {
    vnet_address_space = "10.200.0.0/16"
    client_count       = 2
  }
}