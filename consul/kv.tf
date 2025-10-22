resource "consul_keys" "echo_service" {

  key {
    path  = "echo/param1"
    value = "param_from_consul"
    delete = true
  }
}