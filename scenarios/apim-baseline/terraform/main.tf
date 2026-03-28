locals {
  tags = {
    workload    = var.workload_name
    environment = var.environment
  }
}

module "hub" {
  source   = "./modules/hub"
  location = var.location
  tags     = local.tags
}

module "spoke" {
  source   = "./modules/spoke"
  location = var.location
  tags     = local.tags
}

output "hub" {
  value = module.hub
}

output "spoke" {
  value = module.spoke
}
