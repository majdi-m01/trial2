path "nomad_kv/data/{{identity.entity.aliases.${accessor}.metadata.nomad_namespace}}/{{identity.entity.aliases.${accessor}.metadata.nomad_job_id}}/*" 
{
  capabilities = ["read"]
}

path "nomad_kv/data/{{identity.entity.aliases.${accessor}.metadata.nomad_namespace}}/{{identity.entity.aliases.${accessor}.metadata.nomad_job_id}}" 
{
  capabilities = ["read"]
}

path "nomad_kv/metadata/{{identity.entity.aliases.${accessor}.metadata.nomad_namespace}}/*" 
{
  capabilities = ["list"]
}

path "nomad_kv/metadata/*" 
{
  capabilities = ["list"]
}
