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
# nomad_address = "http://<IP_FROM_NOMAD_CONSUL_INFRA_OUTPUT>:4646"



# 2. To get this token, you must first create it using the root (bootstrap) token.
#
#    Prerequisites:
#      a. You have already run `terraform apply` in the `nomad/nomad_admin`
#         directory to create the "developer" policy.
#      b. You have the Nomad bootstrap token saved.
#
#    Action:
#      Run the following command on your local machine, making sure your
#      NOMAD_TOKEN environment variable is set to the bootstrap token:
#
#      export NOMAD_TOKEN=<YOUR_BOOTSTRAP_TOKEN>
#      nomad acl token create -name="dev-token-for-terraform" -policy="developer"
#
#    Output:
#      You will see output like this. Copy the `Secret ID` value and paste it below.
#
#      Accessor ID  = 8a9b1c2d-....
#      Secret ID    = e1f2a3b4-....  <-- COPY THIS VALUE
#      Name         = dev-token-for-terraform
#      Type         = client
#      Policies     = [developer]
#
# nomad_developer_token = "<PASTE_YOUR_NEWLY_CREATED_DEVELOPER_TOKEN_HERE>"
