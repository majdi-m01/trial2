resource "azurerm_resource_group" "keyvault_rg" {
  name     = var.key_vault_rg_name
  location = var.location

  tags = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                     = "${var.key_vault_name}-${random_string.suffix.result}"
  location                 = azurerm_resource_group.keyvault_rg.location
  resource_group_name      = azurerm_resource_group.keyvault_rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = var.key_vault_sku
  purge_protection_enabled = false # Low cost, disable for easy cleanup

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "Create", "Delete", "List", "Update", "Import", "Backup", "Restore",
      "Recover", "Purge", "GetRotationPolicy", "Purge",  
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete"
    ]
  }

  tags = var.tags
}

resource "azurerm_key_vault_key" "vault_unseal_key" {
  name         = var.vault_key_name
  key_vault_id = azurerm_key_vault.main.id
  key_type     = var.vault_key_type
  key_size     = var.vault_key_size

  key_opts = [
    "unwrapKey",
    "wrapKey",
  ]

  depends_on = [azurerm_key_vault.main]
}