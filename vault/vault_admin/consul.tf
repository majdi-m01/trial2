# vault/vault_admin/consul.tf (Corrected)

### Secrets Engines ###

# used for ACL tokens only -> authenticate persona/deployments
resource "vault_consul_secret_backend" "plant" {
    path                      = "consul_acl"
    description               = "Consul Backend generating Consul ACL Tokens dynamically"
    address                   = var.consul_address
    # FIX: Provide the Consul management token
    token                     = var.consul_bootstrap_token
}


### Auth for GitLab Pipelines ###

# GitLab pipeline authenticates and retrieves Vault token that allows access on
# consul_acl/creds/consul_admin
resource "vault_jwt_auth_backend_role" "consul_admin" {
    backend = vault_jwt_auth_backend.gitlab.path
    role_name = "consul_admin"
    role_type = "jwt"

    user_claim = "project_path"
    groups_claim = "project_path"
    # FIX: Using the correct 'vault_address' variable
    bound_audiences = [var.vault_address]
    bound_claims = {
      project_path : "gitlab/path/to/consul_admin_project"
      environment : "plant_1"
    }
    token_policies = [
      "consul_admin_policy"
    ]
    token_explicit_max_ttl = 60
}

# Auth role for deployment pipelines after getting Vault token
# Allows generating Consul token via consul_acl/creds/consul_admin
resource "vault_consul_secret_backend_role" "admin" {
  backend   = vault_consul_secret_backend.plant.path
  name      = "consul_admin"
  policies  = ["global-management"]
}