variable "resource_group_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "ase_name" {
  type = string
}

variable "dedicated_host_count" {
  type    = number
  default = 0
}

variable "zone_redundant" {
  type    = bool
  default = false
}

variable "internal_load_balancing_mode" {
  type    = string
  default = "Web, Publishing"
}

variable "subnet_id" {
  type = string
}

variable "create_private_dns" {
  type    = bool
  default = true
}

variable "private_dns_resource_group_name" {
  type    = string
  default = ""
}

variable "application_insights_connection_string" {
  type    = string
  default = ""
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "deploy_sample" {
  type    = bool
  default = true
}

variable "app_services" {
  type    = list(any)
  default = []
}

module "ase" {
  source = "./appServiceEnvironment"

  resource_group_id                      = var.resource_group_id
  resource_group_name                    = var.resource_group_name
  location                               = var.location
  tags                                   = var.tags
  ase_name                               = var.ase_name
  dedicated_host_count                   = var.dedicated_host_count
  zone_redundant                         = var.zone_redundant
  internal_load_balancing_mode           = var.internal_load_balancing_mode
  subnet_id                              = var.subnet_id
  create_private_dns                     = var.create_private_dns
  private_dns_resource_group_name        = var.private_dns_resource_group_name
  log_analytics_workspace_id             = var.log_analytics_workspace_id
}

locals {
  app_service_plans = distinct([for item in var.app_services : item.appServicePlanName])
}

module "app_service_plan" {
  for_each = var.deploy_sample ? toset(local.app_service_plans) : toset([])

  source = "./appServicePlan"

  resource_group_name        = var.resource_group_name
  location                   = var.location
  tags                       = var.tags
  app_service_plan_name      = each.key
  app_service_environment_name = module.ase.name
  app_service_plan_capacity  = 1
}

module "site" {
  for_each = var.deploy_sample ? {
    for app in var.app_services : app.name => app
  } : {}

  source = "./appService"

  resource_group_name                     = var.resource_group_name
  location                                = var.location
  tags                                    = var.tags
  app_name                                = each.value.name
  app_service_plan_name                   = each.value.appServicePlanName
  app_service_environment_name            = module.ase.name
  repo_url                                = try(each.value.properties.repoURL, "")
  branch                                  = try(each.value.properties.branch, "main")
  net_framework_version                   = try(each.value.properties.netFrameworkVersion, "v8.0")
  application_insights_connection_string  = var.application_insights_connection_string
  ip_security_restrictions                = []
  app_settings                            = try(each.value.appSettings, [])

  depends_on = [module.app_service_plan]
}

output "name" {
  value = module.ase.name
}

output "id" {
  value = module.ase.id
}

output "resource_group_name" {
  value = module.ase.resource_group_name
}

output "location" {
  value = module.ase.location
}