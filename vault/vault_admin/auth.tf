# vault/vault_admin/auth.tf (Corrected)

resource "vault_jwt_auth_backend" "gitlab" {
    path = "jwt_gitlab"
    bound_issuer = var.gitlab_url
    jwks_url = "${var.gitlab_url}/oauth/discovery/keys"
    default_role = "gitlab_role"
}

# role to manage Vault configuration
resource "vault_jwt_auth_backend_role" "terraform_vault_management_role" {
    backend = vault_jwt_auth_backend.gitlab.path
    role_name = "terraform_vault_management_role"
    role_type = "jwt"

    user_claim = "project_path"
    # FIX: Using the correct 'vault_address' variable
    bound_audiences = [var.vault_address]
    bound_claims = {
      project_path = "vault-tf-management"
    }
    bound_claims_type = "string"
    token_policies = [
      "vault_tf_management_repo_policy"
    ]
    token_explicit_max_ttl = 60
}