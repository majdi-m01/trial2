storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-$(hostname -s)" 

  retry_join {
    # Using the variables defined in the 'locals' block now:
    auto_join = "provider=azure tag_name=VaultCluster tag_value=my-vault-cluster subscription_id=${subscription_id} resource_group=${resource_group_name}"
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