storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-LOCAL_HOSTNAME" 

  retry_join {
    # Using the variables defined in the 'locals' block now, NEEDS permissions, commented for now...
    #auto_join = "provider=azure tag_name=VaultCluster tag_value=my-vault-cluster subscription_id=${subscription_id}"

    leader_api_addr = "${leader_api_addr}"
  }
}

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable     = true
}

seal "azurekeyvault" {
  tenant_id   = "${tenant_id}"
  vault_name  = "${key_vault_name}"
  key_name    = "${key_name}"
}

api_addr     = "${api_addr}"
cluster_addr = "${cluster_addr}"

ui            = true
disable_mlock = true