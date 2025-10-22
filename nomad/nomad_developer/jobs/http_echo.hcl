job "echo" {

  group "example" {
    network {
      port "http" {
        static = "5678"
      }
      mode = "host"
    }

    service {
      provider = "consul"
      name     = "echo"
      port     = "http"
    }

    task "server" {
      driver = "docker"

      vault {
        policies = ["nomad_workloads_policy"]
      }

      template {
        data = <<EOH
ECHO_TEXT="{{key "echo/param1"}} {{with secret "nomad_kv/data/default/echo"}}{{.Data.data.secret1}}{{end}}"
EOH
        destination = "secrets/file.env"
        env = true
      }

      config {
        image = "hashicorp/http-echo"
        ports = ["http"]
        args = [
          "-listen",
          ":5678"
        ]
      }
    }
  }
}