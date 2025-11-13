resource "nomad_job" "echo" {
  jobspec = file("jobs/http_echo.hcl")
}