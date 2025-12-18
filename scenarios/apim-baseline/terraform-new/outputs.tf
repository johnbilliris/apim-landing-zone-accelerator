#--------------------------------------------------------------
# Outputs
#--------------------------------------------------------------

output "hub_network_resource_group_name" {
  description = "The name of the hub network resource group"
  value       = azurerm_resource_group.hub_network.name
}

output "hub_vnet_id" {
  description = "The ID of the hub virtual network"
  value       = module.hub_vnet.id
}

output "hub_vnet_name" {
  description = "The name of the hub virtual network"
  value       = module.hub_vnet.name
}

output "azure_firewall_id" {
  description = "The ID of the Azure Firewall"
  value       = var.deploy_azure_firewall ? module.azure_firewall[0].id : null
}

output "azure_firewall_private_ip" {
  description = "The private IP address of the Azure Firewall"
  value       = var.deploy_azure_firewall ? module.azure_firewall[0].private_ip_address : null
}

output "app_gateway_id" {
  description = "The ID of the Application Gateway"
  value       = var.deploy_app_gateway ? module.app_gateway[0].id : null
}

output "app_gateway_public_ip" {
  description = "The public IP address of the Application Gateway"
  value       = var.deploy_app_gateway ? azurerm_public_ip.app_gateway[0].ip_address : null
}

output "apim_id" {
  description = "The ID of the API Management instance"
  value       = var.deploy_apim ? module.apim[0].id : null
}

output "apim_name" {
  description = "The name of the API Management instance"
  value       = var.deploy_apim ? module.apim[0].name : null
}

output "apim_gateway_url" {
  description = "The gateway URL of the API Management instance"
  value       = var.deploy_apim ? module.apim[0].gateway_url : null
}

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = var.deploy_key_vault ? module.hub_key_vault[0].id : null
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = var.deploy_key_vault ? module.hub_key_vault[0].name : null
}

output "bastion_id" {
  description = "The ID of the Azure Bastion host"
  value       = var.deploy_bastion ? module.bastion[0].id : null
}
