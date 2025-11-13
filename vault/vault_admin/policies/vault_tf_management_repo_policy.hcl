# Allow managing policies
path "sys/policies/acl"
{
    capabilities = ["list"]
}

path "sys/policies/acl/*"
{
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Allow managing auth methods
path "auth/*"
{
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/auth/*"
{
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "sys/auth"
{
    capabilities = ["read"]
}

# Allow reading all mounted secrets engines
path "sys/mounts"
{
    capabilities = ["read"]
}

# Manage secrets engines
# Does allow access tune info, required by terraform
path "sys/mounts/*"
{
    capabilities = ["create", "read", "update", "delete", "sudo"]
}

# Allow managing entities & groups
path "identity/group"
{
    capabilities = ["create", "update", ]
}

path "identity/group/id/+"
{
    capabilities = ["read", "update", "delete"]
}