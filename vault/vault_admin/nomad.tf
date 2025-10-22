# vault/vault_admin/nomad.tf (Corrected)

### Secrets Engines ###

resource "vault_mount" "nomad_kv" {
    path = "nomad_kv"
    type = "kv-v2"
    description = "KV Secrets Engine for Nomad jobs"
    options = {
        version = "2"
        type = "kv-v2"
    }
}

resource "vault_kv_secret_backend_v2" "nomad_kv" {
    mount = vault_mount.nomad_kv.path
}

resource "vault_kv_secret_v2" "echo" {
  mount = vault_mount.nomad_kv.path
  name = "default/echo"
  data_json = jsonencode({
    secret1 = "secret_from_vault"
  })
}

resource "vault_nomad_secret_backend" "plant" {
    backend                   = "nomad_acl"
    description               = "Nomad Secret Backend generating Nomad ACL Tokens dynamically"
    address                   = var.nomad_address
    # FIX: Provide the Nomad management token
    token                     = var.nomad_bootstrap_token
}

### Auth for GitLab Pipelines ###

resource "vault_jwt_auth_backend_role" "nomad_admin" {
    backend = vault_jwt_auth_backend.gitlab.path
    role_name = "nomad_admin"
    role_type = "jwt"
    user_claim = "project_path"
    groups_claim = "project_path"
    # FIX: Using the correct 'vault_address' variable
    bound_audiences = [var.vault_address]
    bound_claims = {
      project_path : "gitlab/path/to/nomad_admin_project"
      environment : "plant_1"
    }
    token_policies = [
      "nomad_admin_policy"
    ]
    token_explicit_max_ttl = 60
}

resource "vault_jwt_auth_backend_role" "nomad_developer" {
    backend = vault_jwt_auth_backend.gitlab.path
    role_name = "nomad_developer"
    role_type = "jwt"
    user_claim = "project_path"
    groups_claim = "project_path"
    # FIX: Using the correct 'vault_address' variable
    bound_audiences = [var.vault_address]
    bound_claims = {
      project_path : "gitlab/path/to/nomad_developer_project"
      environment : "plant_1"
    }
    token_policies = [
      "nomad_developer_policy"
    ]
    token_explicit_max_ttl = 300
}

resource "vault_nomad_secret_role" "admin" {
  backend   = vault_nomad_secret_backend.plant.backend
  role      = "nomad_admin"
  type      = "management"
}

resource "vault_nomad_secret_role" "developer" {
  backend   = vault_nomad_secret_backend.plant.backend
  role      = "nomad_developer"
  type      = "client"
  policies  = ["developer"]
}

### Auth for Nomad Workloads ###

# The 'vault_jwt_auth_backend' and 'vault_jwt_auth_backend_role' resources
# for Nomad Workload Identity depend on the OIDC feature, which is not available
# in open-source Nomad. We are disabling them.

# resource "vault_jwt_auth_backend" "nomad" {
#     path = "jwt_nomad"
#     jwks_url = "http://${var.nomad_private_ip}:4646/.well-known/jwks.json"
#     default_role = "nomad_workloads"
#     jwt_supported_algs = ["RS256", "EdDSA"]
# }

# resource "vault_jwt_auth_backend_role" "nomad_workload" {
#     backend = vault_jwt_auth_backend.nomad.path
#     role_name = "nomad_workloads"
#     role_type = "jwt"
#     user_claim = "/nomad_job_id"
#     user_claim_json_pointer = true
#     claim_mappings = {
#       nomad_namespace = "nomad_namespace"
#       nomad_job_id = "nomad_job_id"
#       nomad_task = "nomad_task"
#     }
#     bound_audiences = [var.vault_address]
#     token_policies = [
#       "nomad_workloads_policy"
#     ]
#     token_type = "service"
#     token_explicit_max_ttl = 0
# }