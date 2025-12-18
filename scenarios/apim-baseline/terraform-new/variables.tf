#--------------------------------------------------------------
# Core Variables
#--------------------------------------------------------------

variable "workload_name" {
  type        = string
  description = "A short name for the workload being deployed (alphanumeric only)"
  default     = "inte"

  validation {
    condition     = length(var.workload_name) <= 8
    error_message = "Workload name must be 8 characters or less"
  }
}

variable "environment" {
  type        = string
  description = "The environment for which the deployment is being executed"
  default     = "dev"

  validation {
    condition     = contains(["dev", "uat", "prod", "dr"], var.environment)
    error_message = "Environment must be one of: dev, uat, prod, dr"
  }
}

variable "location" {
  type        = string
  description = "The Azure location for which the deployment is being executed"
  default     = "australiaeast"

  validation {
    condition     = contains(["australiaeast", "australiasoutheast"], var.location)
    error_message = "Location must be one of: australiaeast, australiasoutheast"
  }
}

variable "hub_subscription_id" {
  type        = string
  description = "The subscription ID for the hub resources"
}

variable "spoke_subscription_id" {
  type        = string
  description = "The subscription ID for the spoke resources"
}

variable "application_insights_subscription_id" {
  type        = string
  description = "The subscription ID for the Application Insights resources"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}

#--------------------------------------------------------------
# Feature Flags
#--------------------------------------------------------------

variable "deploy_sample" {
  type        = bool
  description = "Whether to deploy sample APIs and resources"
  default     = true
}

variable "deploy_apim" {
  type        = bool
  description = "Whether to deploy API Management"
  default     = true
}

variable "deploy_api_center" {
  type        = bool
  description = "Whether to deploy API Center"
  default     = true
}

variable "deploy_app_gateway" {
  type        = bool
  description = "Whether to deploy Application Gateway"
  default     = true
}

variable "deploy_azure_firewall" {
  type        = bool
  description = "Whether to deploy Azure Firewall"
  default     = true
}

variable "deploy_bastion" {
  type        = bool
  description = "Whether to deploy Azure Bastion"
  default     = true
}

variable "deploy_key_vault" {
  type        = bool
  description = "Whether to deploy Key Vault"
  default     = true
}

variable "use_existing_virtual_network" {
  type        = bool
  description = "Whether to use an existing virtual network"
  default     = false
}

variable "use_existing_virtual_network_subnets" {
  type        = bool
  description = "Whether to use existing virtual network subnets"
  default     = false
}

#--------------------------------------------------------------
# Network Variables
#--------------------------------------------------------------

variable "hub_vnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the hub virtual network"
  default     = ["10.132.0.0/24", "10.132.13.0/24"]
}

variable "firewall_private_ip" {
  type        = string
  description = "The private IP address of the Azure Firewall for routing"
  default     = "10.132.0.4"
}

#--------------------------------------------------------------
# APIM Variables
#--------------------------------------------------------------

variable "apim_publisher_email" {
  type        = string
  description = "The email address of the publisher of the APIM resource"
  default     = "apim@contoso.com"
}

variable "apim_publisher_name" {
  type        = string
  description = "Company name of the publisher of the APIM resource"
  default     = "Contoso"
}

variable "apim_sku_name" {
  type        = string
  description = "The pricing tier of the APIM resource"
  default     = "StandardV2"

  validation {
    condition     = contains(["Developer", "Premium", "StandardV2"], var.apim_sku_name)
    error_message = "APIM SKU must be one of: Developer, Premium, StandardV2"
  }
}

variable "apim_capacity" {
  type        = number
  description = "The instance size of the APIM resource"
  default     = 1
}

variable "apim_virtual_network_type" {
  type        = string
  description = "The type of virtual network integration to deploy"
  default     = "External"

  validation {
    condition     = contains(["External", "Internal", "None"], var.apim_virtual_network_type)
    error_message = "APIM virtual network type must be one of: External, Internal, None"
  }
}

variable "apim_availability_zones" {
  type        = list(string)
  description = "Availability zones for APIM (Premium SKU only)"
  default     = ["1", "2", "3"]
}

#--------------------------------------------------------------
# Existing Resources
#--------------------------------------------------------------

variable "log_analytics_workspace_name" {
  type        = string
  description = "Name of the existing Log Analytics workspace"
  default     = "LA-AE-MGMT-01"
}

variable "log_analytics_workspace_resource_group" {
  type        = string
  description = "Resource group of the existing Log Analytics workspace"
  default     = "rg-ae-mgmt-oms-01"
}

variable "sentinel_workspace_name" {
  type        = string
  description = "Name of the existing Sentinel Log Analytics workspace"
  default     = "NDA-COR-AWG-SENTINEL-PROD"
}

variable "sentinel_workspace_resource_group" {
  type        = string
  description = "Resource group of the existing Sentinel Log Analytics workspace"
  default     = "nda-cor-arg-sentinel-prod"
}

variable "application_insights_name" {
  type        = string
  description = "Name of the existing Application Insights resource"
  default     = "appi-ae-mgmt-01"
}

variable "application_insights_resource_group" {
  type        = string
  description = "Resource group of the existing Application Insights resource"
  default     = "rg-ae-mgmt-oms-01"
}
