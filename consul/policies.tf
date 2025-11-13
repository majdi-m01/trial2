resource "consul_acl_policy" "nomad_agent" {
  name        = "nomad_agent"
  description = "Grant necessary permissions to Nomad Agents"
  rules       = file("policies/nomad_agent.hcl")
}

resource "consul_acl_policy" "nomad_tasks" {
  name        = "task_policy"
  description = "ACL policy used by Nomad tasks"
  rules       = file("policies/nomad_tasks.hcl")
}