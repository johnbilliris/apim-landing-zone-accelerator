# APIM Landing Zone Accelerator - Terraform

This Terraform configuration deploys an Azure API Management landing zone, equivalent to the Bicep deployment in the parent `bicep` folder.

## Architecture

This deployment creates:

- **Hub Virtual Network** with subnets for:
  - Azure Firewall
  - Azure Bastion
  - Application Gateway
  - API Management
  - Private Endpoints
  - Gateway

- **Azure Firewall** with application and network rules for APIM

- **Azure Bastion** for secure VM access

- **Application Gateway** with WAF v2 for frontend load balancing

- **API Management** with:
  - Private DNS Zone
  - Private Endpoint (for StandardV2 SKU)
  - Application Insights integration
  - Key Vault access
  - Sample APIs (optional)

- **Key Vault** for secrets and certificates

## Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** v1.5.0 or later
3. **Azure subscription** with required permissions
4. **Existing resources** (referenced by this deployment):
   - Log Analytics Workspace
   - Sentinel Log Analytics Workspace
   - Application Insights (optional)

## Directory Structure

```
terraform-new/
├── main.tf                  # Main deployment configuration
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── locals.tf                # Local values and naming conventions
├── providers.tf             # Provider configuration
├── versions.tf              # Terraform and provider versions
├── terraform.tfvars.example # Example variables file
├── README.md                # This file
└── modules/
    ├── api/
    │   ├── apim/            # API Management module
    │   └── apim-nsg/        # APIM Network Security Group
    ├── gateway/
    │   └── appgw/           # Application Gateway module
    ├── networking/
    │   ├── bastion/         # Azure Bastion module
    │   ├── bastion-nsg/     # Bastion NSG module
    │   ├── firewall/        # Azure Firewall module
    │   ├── nsg/             # Generic NSG module
    │   ├── route-table/     # Route Table module
    │   └── vnet/            # Virtual Network module
    └── shared/
        ├── dns-zone/        # Private DNS Zone module
        ├── keyvault/        # Key Vault module
        └── private-endpoint/# Private Endpoint module
```

## Deployment Instructions

### 1. Clone and Navigate

```bash
cd scenarios/apim-baseline/terraform-new
```

### 2. Configure Variables

Copy the example variables file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to set your:
- Subscription IDs
- Existing resource names (Log Analytics, Application Insights)
- APIM configuration
- Network settings

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan -out=tfplan
```

### 5. Apply the Configuration

```bash
terraform apply tfplan
```

Or apply directly with auto-approve (use with caution):

```bash
terraform apply -auto-approve
```

### 6. View Outputs

After successful deployment:

```bash
terraform output
```

## Deployment Commands (PowerShell)

```powershell
# Navigate to the Terraform directory
cd C:\code\apim-landing-zone-accelerator\scenarios\apim-baseline\terraform-new

# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Initialize Terraform
terraform init

# Validate the configuration
terraform validate

# Plan the deployment
terraform plan -out=tfplan

# Apply the deployment
terraform apply tfplan

# View outputs
terraform output
```

## Deployment Commands (Bash)

```bash
# Navigate to the Terraform directory
cd /c/code/apim-landing-zone-accelerator/scenarios/apim-baseline/terraform-new

# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Initialize Terraform
terraform init

# Validate the configuration
terraform validate

# Plan the deployment
terraform plan -out=tfplan

# Apply the deployment
terraform apply tfplan

# View outputs
terraform output
```

## Configuration Options

### APIM SKU Options

| SKU | Description | Virtual Network Support |
|-----|-------------|------------------------|
| `Developer` | Development/testing | Internal/External |
| `Premium` | Production with zones | Internal/External |
| `StandardV2` | Production (new) | Private Endpoint only |

### Feature Flags

| Variable | Default | Description |
|----------|---------|-------------|
| `deploy_apim` | `true` | Deploy API Management |
| `deploy_app_gateway` | `true` | Deploy Application Gateway |
| `deploy_azure_firewall` | `true` | Deploy Azure Firewall |
| `deploy_bastion` | `true` | Deploy Azure Bastion |
| `deploy_key_vault` | `true` | Deploy Key Vault |
| `deploy_sample` | `true` | Deploy sample APIs |

## Remote State Configuration

For production deployments, configure remote state:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "apim-landing-zone.tfstate"
  }
}
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Provider authentication**: Ensure you're logged in via `az login`
2. **Permissions**: Verify you have Owner or Contributor role on the subscription
3. **Existing resources**: Ensure referenced Log Analytics and App Insights resources exist
4. **Name conflicts**: Some resources require globally unique names (Key Vault, APIM)

### Logs and Diagnostics

View Terraform logs:

```bash
export TF_LOG=DEBUG
terraform apply
```

## Module Reference

### Networking Module

The networking module creates:
- Virtual Network with configurable subnets
- NSG associations
- Route Table associations
- Diagnostic settings

### APIM Module

The APIM module creates:
- API Management service
- Private DNS Zone
- Private Endpoint (StandardV2)
- Application Insights integration
- Sample products and groups

### Application Gateway Module

The App Gateway module creates:
- Application Gateway with WAF v2
- WAF Policy
- User-assigned managed identity
- Backend pool for APIM

## Contributing

When making changes:
1. Run `terraform fmt` to format code
2. Run `terraform validate` to check syntax
3. Update documentation as needed

## License

See the [LICENSE](../../../../LICENSE) file in the root of the repository.
