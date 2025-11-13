resource "nomad_acl_policy" "developer" {
  name        = "developer"
  description = "Submit jobs to nomad and control its lifecycle"
  rules_hcl   = file("policies/developer_policy.hcl")
}
