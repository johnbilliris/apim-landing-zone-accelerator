variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "app_gateway_name" {
  type = string
}

variable "app_gateway_waf_policy_name" {
  type = string
}

variable "app_gateway_subnet_id" {
  type = string
}

variable "primary_backend_end_fqdn" {
  type = string
}

variable "probe_url" {
  type    = string
  default = "/status-0123456789abcdef"
}

variable "app_gateway_public_ip_name" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "key_vault_resource_group_name" {
  type = string
}

resource "azurerm_user_assigned_identity" "app_gateway_identity" {
  name                = "AppGatewayManagedIdentity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

data "azurerm_key_vault" "key_vault" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

resource "azurerm_role_assignment" "certificates_officer" {
  scope                = data.azurerm_key_vault.key_vault.id
  role_definition_id   = "/providers/Microsoft.Authorization/roleDefinitions/a4417e6f-fecd-4de8-b567-7b0420556985"
  principal_id         = azurerm_user_assigned_identity.app_gateway_identity.principal_id
}

resource "azurerm_role_assignment" "secrets_user" {
  scope                = data.azurerm_key_vault.key_vault.id
  role_definition_id   = "/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6"
  principal_id         = azurerm_user_assigned_identity.app_gateway_identity.principal_id
}

data "azurerm_public_ip" "app_gateway_public_ip" {
  name                = var.app_gateway_public_ip_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_web_application_firewall_policy" "app_gateway_waf" {
  name                = var.app_gateway_waf_policy_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  policy_settings {
    enabled = true
    mode    = "Prevention"
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway" "app_gateway" {
  name                = var.app_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.app_gateway_waf.id
  tags                = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_gateway_identity.id]
  }

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.app_gateway_subnet_id
  }

  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = data.azurerm_public_ip.app_gateway_public_ip.id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  backend_address_pool {
    name  = "apim"
    fqdns = [var.primary_backend_end_fqdn]
  }

  probe {
    name     = "apim-demo-apis-http"
    protocol = "Https"
    host     = var.primary_backend_end_fqdn
    path     = var.probe_url
    interval = 30
    timeout  = 30
    unhealthy_threshold = 3
    match {
      status_code = ["200-399"]
    }
  }

  backend_http_settings {
    name                                = "apim-http-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 20
    host_name                           = var.primary_backend_end_fqdn
    probe_name                          = "apim-demo-apis-http"
    pick_host_name_from_backend_address = false
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appGwPublicFrontendIp"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "apim-rule"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "apim"
    backend_http_settings_name = "apim-http-settings"
  }

  depends_on = [
    azurerm_role_assignment.certificates_officer,
    azurerm_role_assignment.secrets_user,
  ]
}

output "name" {
  value = azurerm_application_gateway.app_gateway.name
}

output "id" {
  value = azurerm_application_gateway.app_gateway.id
}

output "location" {
  value = azurerm_application_gateway.app_gateway.location
}

output "resource_group_name" {
  value = azurerm_application_gateway.app_gateway.resource_group_name
}

output "app_gateway_public_ip_address" {
  value = data.azurerm_public_ip.app_gateway_public_ip.ip_address
}