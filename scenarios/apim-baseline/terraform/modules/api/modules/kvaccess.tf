variable "key_vault_name" {
  type = string
}

variable "key_vault_resource_group_name" {
  type = string
}

variable "managed_identity" {
  type = object({
    principalId = string
    tenantId    = string
  })
}

data "azurerm_key_vault" "key_vault" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

resource "azurerm_key_vault_access_policy" "access_policy_grant" {
  key_vault_id = data.azurerm_key_vault.key_vault.id
  tenant_id    = var.managed_identity.tenantId
  object_id    = var.managed_identity.principalId

  secret_permissions = [
    "Get",
    "List",
  ]

  certificate_permissions = [
    "Get",
    "List",
  ]
}