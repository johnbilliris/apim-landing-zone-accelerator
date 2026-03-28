variable "resource_group_id" {
  type = string
}

variable "apim_name" {
  type = string
}

locals {
  apim_id = "${var.resource_group_id}/providers/Microsoft.ApiManagement/service/${var.apim_name}"
}

resource "azapi_resource" "administrators" {
  type      = "Microsoft.ApiManagement/service/groups@2024-06-01-preview"
  name      = "administrators"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName = "Administrators"
      description = "Administrators is a built-in group containing the admin email account provided at the time of service creation. Its membership is managed by the system."
      type        = "system"
    }
  }
}

resource "azapi_resource" "developers" {
  type      = "Microsoft.ApiManagement/service/groups@2024-06-01-preview"
  name      = "developers"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName = "Developers"
      description = "Developers is a built-in group. Its membership is managed by the system. Signed-in users fall into this group."
      type        = "system"
    }
  }
}

resource "azapi_resource" "guests" {
  type      = "Microsoft.ApiManagement/service/groups@2024-06-01-preview"
  name      = "guests"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName = "Guests"
      description = "Guests is a built-in group. Its membership is managed by the system. Unauthenticated users visiting the developer portal fall into this group."
      type        = "system"
    }
  }
}

resource "azapi_resource" "starter" {
  type      = "Microsoft.ApiManagement/service/products@2024-06-01-preview"
  name      = "Starter"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName          = "Starter"
      description          = "Subscribers will be able to run 5 calls/minute up to a maximum of 100 calls/week."
      subscriptionRequired = true
      approvalRequired     = false
      subscriptionsLimit   = 1
      state                = "published"
    }
  }
}

resource "azapi_resource" "unlimited" {
  type      = "Microsoft.ApiManagement/service/products@2024-06-01-preview"
  name      = "Unlimited"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName          = "Unlimited"
      description          = "Subscribers have completely unlimited access to the API. Administrator approval is required."
      subscriptionRequired = true
      approvalRequired     = true
      subscriptionsLimit   = 1
      state                = "published"
    }
  }
}

resource "azapi_resource" "starter_administrators" {
  type      = "Microsoft.ApiManagement/service/products/groups@2024-06-01-preview"
  name      = "administrators"
  parent_id = azapi_resource.starter.id
  depends_on = [azapi_resource.administrators]
}

resource "azapi_resource" "unlimited_administrators" {
  type      = "Microsoft.ApiManagement/service/products/groups@2024-06-01-preview"
  name      = "administrators"
  parent_id = azapi_resource.unlimited.id
  depends_on = [azapi_resource.administrators]
}

resource "azapi_resource" "starter_developers" {
  type      = "Microsoft.ApiManagement/service/products/groups@2024-06-01-preview"
  name      = "developers"
  parent_id = azapi_resource.starter.id
  depends_on = [azapi_resource.developers]
}

resource "azapi_resource" "unlimited_developers" {
  type      = "Microsoft.ApiManagement/service/products/groups@2024-06-01-preview"
  name      = "developers"
  parent_id = azapi_resource.unlimited.id
  depends_on = [azapi_resource.developers]
}

resource "azapi_resource" "starter_guests" {
  type      = "Microsoft.ApiManagement/service/products/groups@2024-06-01-preview"
  name      = "guests"
  parent_id = azapi_resource.starter.id
  depends_on = [azapi_resource.guests]
}

resource "azapi_resource" "unlimited_guests" {
  type      = "Microsoft.ApiManagement/service/products/groups@2024-06-01-preview"
  name      = "guests"
  parent_id = azapi_resource.unlimited.id
  depends_on = [azapi_resource.guests]
}


