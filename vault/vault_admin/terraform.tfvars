# ------------------------------------------------------------------------------
# EXAMPLE for terraform.tfvars
#
# Create a new file in this directory named 'terraform.tfvars' and copy the
# content below into it. Then, fill in your actual values.
#
# !!! DO NOT commit your real terraform.tfvars file to version control !!!
# ------------------------------------------------------------------------------


# 1. Get this IP address from the `vault_access_public_ip` output
#    after running `terraform apply` in the `infra/` directory.
# vault_address = "http://<IP_FROM_VAULT_INFRA_OUTPUT>:8200"

# 2. Get this token by SSH-ing into the 'vault-server-0' VM and running the
#    `vault operator init` command. Copy the `Initial Root Token` value here.
# vault_root_token = "<PASTE_YOUR_VAULT_ROOT_TOKEN_HERE>"

# 3. Get this IP address from the `nomad_consul_access_public_ip` output
#    after running `terraform apply` in the `infra/` directory.
# nomad_address = "http://<IP_FROM_NOMAD_CONSUL_INFRA_OUTPUT>:4646"

# 4. Get this IP address from the `nomad_consul_access_public_ip` output
#    after running `terraform apply` in the `infra/` directory.
# consul_address = "http://<IP_FROM_NOMAD_CONSUL_INFRA_OUTPUT>:8500"

# --- ADD THESE NEW VALUES ---

# The PRIVATE IP of your Nomad/Consul server (from `terraform output` in the infra dir)
# nomad_private_ip = "<IP_OF_PRIVATE_NOMAD_SERVER>"

# The root token (Secret ID) you got from `sudo nomad acl bootstrap`
# nomad_bootstrap_token = "<PASTE_YOUR_NOMAD_ROOT_TOKEN_HERE>"


# The root token (SecretID) you got from `sudo cat /opt/consul/consul.token`
# consul_bootstrap_token = "<PASTE_YOUR_CONSUL_ROOT_TOKEN_HERE>"

