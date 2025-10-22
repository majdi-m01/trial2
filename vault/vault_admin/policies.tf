resource "vault_policy" "vault_tf_management_repo_policy" {
    name = "vault_tf_management_repo_policy"
    policy = file("policies/vault_tf_management_repo_policy.hcl")
}

resource "vault_policy" "consul_admin_policy" {
    name = "consul_admin_policy"
    policy = file("policies/consul_admin_policy.hcl")
}

resource "vault_policy" "nomad_admin_policy" {
    name = "nomad_admin_policy"
    policy = file("policies/nomad_admin_policy.hcl")
}

resource "vault_policy" "nomad_developer_policy" {
    name = "nomad_developer_policy"
    policy = file("policies/nomad_developer_policy.hcl")
}

# resource "vault_policy" "nomad_workloads_policy" {
#     name = "nomad_workloads_policy"
#     policy = templatefile("policies/nomad_workloads_policy.hcl", {
#         accessor = vault_jwt_auth_backend.nomad.accessor
#     })
# }