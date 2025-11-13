# resource "consul_acl_auth_method" "nomad_workloads" {
#   name          = "nomad-workloads"
#   type          = "jwt"
#   description   = "JWT auth method for Nomad services and workloads"
#
#   config_json = jsonencode({
#     BoundAudiences = [
#       "http://127.0.0.1:8500"
#     ]
#     ClaimMappings = {
#       "nomad_job_id": "nomad_job_id",
#       "nomad_namespace": "nomad_namespace",
#       "nomad_service": "nomad_service",
#       "nomad_task": "nomad_task"
#     }
#     "JWKSURL": "http://127.0.0.1:4646/.well-known/jwks.json",
#     "JWTSupportedAlgs": [
#       "RS256"
#     ]
#   })
# }
#
# resource "consul_acl_binding_rule" "nomad_workloads" {
#   auth_method = consul_acl_auth_method.nomad_workloads.name
#   description = "Binding rule for services registered from Nomad"
#   selector    = "\"nomad_service\" in value"
#   bind_type   = "service"
#   bind_name   = "$${value.nomad_service}"
# }
#
# resource "consul_acl_binding_rule" "tasks" {
#   auth_method = consul_acl_auth_method.nomad_workloads.name
#   description = "Binding rule for Nomad tasks"
#   selector    = "\"nomad_service\" not in value"
#   bind_type   = "role"
#   bind_name   = "default"
# }
#
# resource "consul_acl_role" "tasks" {
#   name        = "default"
#   description = "ACL role for Nomad tasks"
#   policies    = [consul_acl_policy.nomad_tasks.name]
# }