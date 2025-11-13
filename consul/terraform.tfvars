# ------------------------------------------------------------------------------
# EXAMPLE for terraform.tfvars
#
# Create a new file in this directory named 'terraform.tfvars' and copy the
# content below into it. Then, fill in your actual values.
#
# !!! DO NOT commit your real terraform.tfvars file to version control !!!
# ------------------------------------------------------------------------------


# 1. Get this IP address from the `nomad_consul_access_public_ip` output
#    after running `terraform apply` in the `infra/` directory.
# consul_address = "http://<IP_FROM_INFRA_OUTPUT>:8500"

# 2. Get this token by SSH-ing into the 'nc-server-0' VM and running the
#    `consul acl bootstrap` command. Copy the `SecretID` value here.
# consul_bootstrap_token = "<PASTE_YOUR_CONSUL_BOOTSTRAP_TOKEN_HERE>"
