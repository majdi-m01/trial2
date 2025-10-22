resource "consul_acl_token" "nomad_agent" {
  description = "Nomad Agent Token"
  policies    = [consul_acl_policy.nomad_agent.name]
  node_identities {
    datacenter = "azure"
    node_name = "nodeb"
  }
}