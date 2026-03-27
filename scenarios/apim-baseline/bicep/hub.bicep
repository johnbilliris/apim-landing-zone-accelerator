targetScope = 'subscription'

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Core Parameters
@description('The Azure location for which the deployment is being executed')
@allowed([
  'australiaeast'
  'australiasoutheast'
])
param location string

// Parameters
@description('Tags to be applied to all resources.')
param tags object = {}

@description('Whether to deploy sample APIs and resources.')
param deploySample bool

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Network Parameters
@description('The hub resource group name.')
param hubResourceGroupName string

@description('The hub virtual network name.')
param virtualNetworkName string

@description('The hub virtual network address prefixes.')
param virtualNetworkAddressPrefixes array

@description('The hub virtual network subnets.')
param virtualNetworkSubnets array

@description('The gateway subnet route table name.')
param routeTableGatewaySubnetName string = 'GatewayRouteTable'

param privateEndpointSubnetName string
param privateEndpointNetworkSecurityGroupName string
param privateEndpointRouteTableName string

@description('Whether to use an existing virtual network and subnets.')
param useExistingVirtualNetwork bool = true

@description('Whether to use existing virtual network subnets.')
param useExistingVirtualNetworkSubnets bool = true

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// API
@description('The API Center name.')
param apiCenterName string

@description('Whether to deploy the API Center.')
param deployApiCenter bool = true

@description('The API Management service name.')
param apimName string

@description('The API Management publisher email.')
param apimPublisherEmail string

@description('The API Management publisher name.')
param apimPublisherName string

@description('The API Management SKU name.')
param apimSkuName string

@description('The API Management capacity.')
param apimCapacity int = 1

@description('The API Management virtual network type.')
param apimVirtualNetworkType string

@description('The API Management subnet name.')
param apimSubnetName string

@description('The API Management network security group name.')
param apimNetworkSecurityGroupName string

@description('The API Management route table name.')
param apimRouteTableName string

@description('The API Management resource group name.')
param apimResourceGroupName string

@description('The API Management availability zones.')
param apimAvailabilityZones array

param apimPrivateEndpointName string
param apimPrivateEndpointNetworkInterfaceName string

@description('Whether to deploy API Management.')
param deployApim bool = true

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// App Gateway Parameters
@description('Name of the Application Gateway resource.')
param appGatewayName string

@description('Name of the Application Gateway public IP address.')
param appGatewayPublicIPName string

@description('Name of the Application Gateway WAF Policy.')
param appGatewayWAFPolicyName string

@description('Whether to deploy the Application Gateway.')
param deployAppGateway bool = true

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Application Insights Parameters
param applicationInsightsId string = ''
param applicationInsightsConnectionString string = ''

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure Firewall Parameters
@description('The Azure Firewall name.')
param azureFirewallName string

@description('The Azure Firewall public IP name.')
param azureFirewallPublicIpName string

@description('Whether to deploy Azure Firewall.')
param deployAzureFirewall bool = true

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Bastion Parameters
@description('The bastion host name.')
param bastionHostName string

@description('The bastion resource group name.')
param bastionResourceGroupName string

@description('The public IP name for the bastion host.')
param bastionPublicIPName string

@description('The bastion network security group name.')
param bastionNetworkSecurityGroupName string

@description('Whether to deploy the bastion host.')
param deployBastion bool = true

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Key Vault Parameters
@description('The key vault name.')
param keyVaultName string

@description('Whether to deploy the Key Vault.')
param deployKeyVault bool = true

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Log Analytics Parameters
@description('The Log Analytics workspace.')
param logAnalyticsWorkspaceId string

@description('An array of Diagnostic Settings to be applied to resources for Log Analytics.')
param logAnalyticsDiagnosticSettings array = []

@description('The Sentinel Log Analytics workspace.')
#disable-next-line no-unused-params
param sentinelLogAnalyticsWorkspaceId string

@description('An array of Diagnostic Settings to be applied to resources for Sentinel.')
param sentinelDiagnosticSettings array = []


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Global Variables


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Resource Names


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Resource Groups
resource hubResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: hubResourceGroupName
  location: location
  tags: tags
}

resource bastionResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: bastionResourceGroupName
  location: location
  tags: tags
}

resource apimResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: apimResourceGroupName
  location: location
  tags: tags
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Network Security Groups
module apimNetworkSecurityGroup './api/modules/api-management-nsg.bicep' = if (deployApim) {
  name: 'apimNetworkSecurityGroupDeployment'
  scope: hubResourceGroup
  params: {
    location: location
    tags: tags
    nsgName: apimNetworkSecurityGroupName
  }
}

module privateEndpointNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.2' = {
  name: 'privateEndpointNetworkSecurityGroupDeployment'
  scope: hubResourceGroup
  params: {
    name: privateEndpointNetworkSecurityGroupName
    location: location
    tags: tags
    securityRules: []
  }
}

module bastionNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.2' = if (deployBastion) {
  name: 'bastionNetworkSecurityGroupDeployment'
  scope: hubResourceGroup
  params: {
    name: bastionNetworkSecurityGroupName
    location: location
    tags: tags
    securityRules: [
      {
        name: 'Inbound-HTTPS-Allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Inbound-GWManager-Allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Inbound-LoadBalancer-Allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 140
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Inbound-BastionHostComms-Allow'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 160
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Outbound-BastionHostComms-Allow'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 180
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Outbound-SSH-Allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Outbound-RDP-Allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 220
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Outbound-HTTPStoAzureCloud'
        properties: {
          description: 'Egress Traffic to other public endpoints in Azure'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 240
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Outbound-HTTPtoInternetd'
        properties: {
          description: 'Egress Traffic to other public endpoints in Azure'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 260
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

module apimRouteTable 'br/public:avm/res/network/route-table:0.5.0' = if (deployApim) {
  name: 'apimRouteTableDeployment'
  scope: hubResourceGroup
  params: {
    name: apimRouteTableName
    location: location
    tags: tags
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'ApiManagementControlPlane'
        properties: {
          addressPrefix: 'ApiManagement'
          nextHopType: 'Internet'
        }
      }
      {
        name: 'DefaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
      }
    ]
  }
}

module gatewayRouteTable 'br/public:avm/res/network/route-table:0.5.0' = {
  name: 'gatewayRouteTableDeployment'
  scope: hubResourceGroup
  params: {
    name: routeTableGatewaySubnetName
    location: location
    tags: tags
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'VNET-AE-IDENTITY-01'
        properties: {
          addressPrefix: '10.132.2.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      {
        name: 'VNET-AE-MGMT-01'
        properties: {
          addressPrefix: '10.132.1.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      {
        name: 'VNET-AE-ARC-01'
        properties: {
          addressPrefix: '10.132.12.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      {
        name: 'VNET-AE-DATAA-DEV-01'
        properties: {
          addressPrefix: '10.132.5.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      {
        name: 'VNET-AE-DATAA-PROD-01'
        properties: {
          addressPrefix: '10.132.4.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      {
        name: 'VNET-AE-INTE-DEV-01'
        properties: {
          addressPrefix: '10.132.9.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      {
        name: 'VNET-AE-INTE-PROD-01'
        properties: {
          addressPrefix: '10.132.8.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      {
        name: 'VNET-AE-INTE-TEST-01'
        properties: {
          addressPrefix: '10.132.10.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      {
        name: 'ND-PRD-ARG-Fileshares-vnet'
        properties: {
          addressPrefix: '10.2.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      {
        name: 'NDA-SYD-COR-VNT-10.1.0.0'
        properties: {
          addressPrefix: '10.1.0.0/20'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      {
        name: 'NDA-SYD-NPE-VNT-10.1.32.0'
        properties: {
          addressPrefix: '10.1.32.0/20'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
      {
        name: 'NDA-SYD-PRD-VNT-10.1.16.0'
        properties: {
          addressPrefix: '10.1.16.0/20'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
    ]
  }
}

module privateEndpointRouteTable 'br/public:avm/res/network/route-table:0.5.0' = {
  name: 'privateEndpointRouteTableDeployment'
  scope: hubResourceGroup
  params: {
    name: privateEndpointRouteTableName
    location: location
    tags: tags
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'DefaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.132.0.4'
        }
      }
    ]
  }
}

// ---- Create Virtual Network with subnets ----

module hubVirtualNetwork './networking/networking.bicep' = {
  name: 'hubNetworkDeployment'
  scope: hubResourceGroup
  dependsOn: [
    apimNetworkSecurityGroup
    privateEndpointNetworkSecurityGroup
    bastionNetworkSecurityGroup
    apimRouteTable
    gatewayRouteTable
    privateEndpointRouteTable
  ]
  params: {
    useExistingVirtualNetwork: useExistingVirtualNetwork
    useExistingVirtualNetworkSubnets: useExistingVirtualNetworkSubnets
    virtualNetworkName: virtualNetworkName
    vNetAddressPrefixes: virtualNetworkAddressPrefixes
    location: location
    tags: tags
    subnets: virtualNetworkSubnets 
    diagnosticSettings: union(logAnalyticsDiagnosticSettings, sentinelDiagnosticSettings)
    deployDns: false
  }
}

// Variables that depend on hubVirtualNetwork outputs
@description('The subnet resource id to use for APIM.')
var apimSubnetId = filter(hubVirtualNetwork.outputs.deployedSubnets, subnet => subnet.name == apimSubnetName)[0].resourceId
var privateEndpointSubnetId = filter(hubVirtualNetwork.outputs.deployedSubnets, subnet => subnet.name == privateEndpointSubnetName)[0].resourceId
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure Firewall

module azureFirewall 'br/public:avm/res/network/azure-firewall:0.9.1' = if (deployAzureFirewall) {
  name: 'azureFirewallDeployment'
  scope: hubResourceGroup
  params: {
    // Required parameters
    name: azureFirewallName
    // Non-required parameters
    applicationRuleCollections: union(deploySample ? [
      {
        name: 'allow-sampleapp-rules'
        properties: {
          action: {
            type: 'Allow'
          }
          priority: 110
          rules: [
            {
              name: 'allow-echo-api'
              protocols: [
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: [
                'echo.playground.azure-api.net'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
            {
              name: 'allow-colors-api'
              protocols: [
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: [
                'colors-api.azurewebsites.net'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
            {
              name: 'allow-github'
              protocols: [
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: [
                'github.com'
                'www.github.com'
                '*.github.com'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
            {
              name: 'allow-nuget'
              protocols: [
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: [
                'nuget.org'
                'www.nuget.org'
                'api.nuget.org'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
          ]
        }
      }
    ] : [], [
      {
        name: 'allow-app-rules'
        properties: {
          action: {
            type: 'Allow'
          }
          priority: 100
          rules: [
            {
              fqdnTags: [
                'AppServiceEnvironment'
                'WindowsUpdate'
              ]
              name: 'allow-ase-tags'
              protocols: [
                {
                  port: 80
                  protocolType: 'Http'
                }
                {
                  port: 443
                  protocolType: 'Https'
                }
              ]
              sourceAddresses: [
                '*'
              ]
            }
            {
              name: 'allow-ase-management'
              protocols: [
                {
                  port: 80
                  protocolType: 'Http'
                }
                {
                  port: 443
                  protocolType: 'Https'
                }
              ]
              sourceAddresses: [
                '*'
              ]
              targetFqdns: [
                'bing.com'
              ]
            }
            {
              name: 'allow-apim-capture'
              protocols: [
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: [
                'partner.prod.repmap.microsoft.com'
                'dc.services.visualstudio.com'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
            {
              name: 'allow-apim-metrics'
              protocols: [
                {
                  protocolType: 'Https'
                  port: 1886
                }
              ]
              fqdnTags: []
              targetFqdns: [
                'prod3.prod.microsoftmetrics.com'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
            {
              name: 'allow-app-insights'
              protocols: [
                {
                  protocolType: 'Https'
                  port: 1886
                }
              ]
              fqdnTags: []
              targetFqdns: [
                '*.applicationinsights.azure.com'
                '*.monitor.azure.com'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
            {
              name: 'allow-certs'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
              ]
              fqdnTags: []
              targetFqdns: [
                's.symcd.com'
                'ts-ocsp.ws.symantec.com'
                'ocsp.digicert.com'
                'ts-crl.ws.symantec.com'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
          ]
        }
      }
    ])
    availabilityZones: [
      1
      2
      3
    ]
    diagnosticSettings: [
        for (diagnosticSetting, index) in (sentinelDiagnosticSettings ?? []): {
        name: '${diagnosticSetting.?namePrefix}${azureFirewallName}-${diagnosticSetting.?destinationSuffix}'
        workspaceResourceId: diagnosticSetting.?workspaceResourceId
        logCategoriesAndGroups: diagnosticSetting.?logCategoriesAndGroups
        metricCategories: diagnosticSetting.?metricCategories
      }
    ]
    location: location
    networkRuleCollections: [
      {
        name: 'allow-network-rules'
        properties: {
          action: {
            type: 'Allow'
          }
          priority: 100
          rules: [
            {
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '12000'
                '123'
              ]
              name: 'allow-ntp'
              protocols: [
                'Any'
              ]
              sourceAddresses: [
                '*'
              ]
            }
          ]
        }
      }
    ]
    tags: tags
    virtualNetworkResourceId: hubVirtualNetwork.outputs.id
    publicIPAddressObject: {
      diagnosticSettings: [
          for (diagnosticSetting, index) in (sentinelDiagnosticSettings ?? []): {
          name: '${diagnosticSetting.?namePrefix}${azureFirewallPublicIpName}-${diagnosticSetting.?destinationSuffix}'
          workspaceResourceId: diagnosticSetting.?workspaceResourceId
          logCategoriesAndGroups: diagnosticSetting.?logCategoriesAndGroups
          metricCategories: diagnosticSetting.?metricCategories
        }
      ]
      name: azureFirewallPublicIpName
      publicIPAllocationMethod: 'Static'
      publicIPAddressVersion: 'IPv4'
      skuName: 'Standard'
      skuTier: 'Regional'
    }
  }
}

resource azureFirewallExisting 'Microsoft.Network/azureFirewalls@2025-01-01' existing = if (!deployAzureFirewall) {
  name: azureFirewallName
  scope: hubResourceGroup
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure Application Gateway
@description('Resource ID of the Application Gateway subnet.')
var applicationGatewaySubnetId = filter(hubVirtualNetwork.outputs.deployedSubnets, subnet => subnet.name == 'AppGatewaySubnet')[0].resourceId
var azureApplicationGatewaySubnetId = filter(hubVirtualNetwork.outputs.deployedSubnets, subnet => subnet.name == 'AzureAppGatewaySubnet')[0].resourceId

module publicIpAddress 'br/public:avm/res/network/public-ip-address:0.9.1' = if (deployAppGateway) {
  name: 'publicIpAddressDeployment'
  scope: hubResourceGroup
  params: {
    // Required parameters
    name: appGatewayPublicIPName
    // Non-required parameters
    availabilityZones: [
      1
      2
      3
    ]
    location: location
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    tags: tags
  }
}

module keyVault './shared/modules/keyvault.bicep' = if (deployKeyVault) {
  name: 'hubKeyVaultDeployment'
  scope: hubResourceGroup
  params: {
    keyVaultName: keyVaultName
    location: location
    tags: tags
    privateEndpointSubnetId: '' //privateEndpointSubnetId
    privateDnsZoneResourceId: '' // privateDnsZoneResourceId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    diagnosticSettings: logAnalyticsDiagnosticSettings
    virtualNetworkRules: !deployAppGateway ? [] : [
      {
          id: applicationGatewaySubnetId
          ignoreMissingVnetServiceEndpoint: false
        }
        {
          id: azureApplicationGatewaySubnetId
          ignoreMissingVnetServiceEndpoint: false
        }
    ]
    secrets: []
  }
}

module appGateway 'gateway/appgw.bicep' = if (deployAppGateway) {
  name: 'appGatewayDeployment'
  scope: hubResourceGroup
  dependsOn: [
    keyVault
  ]
  params: {
    appGatewayName: appGatewayName
    appGatewayWAFPolicyName: appGatewayWAFPolicyName
    location: location
    appGatewaySubnetId: applicationGatewaySubnetId
    primaryBackendEndFQDN: '${apimName}.azure-api.net'
    keyVaultName: keyVaultName
    #disable-next-line BCP318
    appGatewayPublicIpName: publicIpAddress.outputs.name
    tags: tags
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure Bastion
module bastionHost 'networking/bastionhost.bicep' = if (deployBastion) {
  name: 'bastionHostHubDeployment'
  scope: bastionResourceGroup
  params: {
    hostName: bastionHostName
    publicIpName: bastionPublicIPName
    location: location
    virtualNetworkId: hubVirtualNetwork.outputs.id
    workspaceResourceId: logAnalyticsWorkspaceId
    diagnosticSettings: logAnalyticsDiagnosticSettings
    tags: tags
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure APIM
module apiManagement './api/apim.bicep' = if (deployApim) {
  name: 'apimDeployment'
  scope: apimResourceGroup
  dependsOn: [
    appGateway
    apimNetworkSecurityGroup
    apimRouteTable
    keyVault
  ]
  params: {
    apimName: apimName
    apimSubnetId: apimSubnetId
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
    skuName: apimSkuName
    availabilityZones: apimAvailabilityZones
    capacity: apimCapacity
    virtualNetworkType: apimVirtualNetworkType
    location: location
    tags: tags
    applicationInsightsId: applicationInsightsId
    applicationInsightsConnectionString: applicationInsightsConnectionString
    keyVaultName: keyVaultName
    keyVaultResourceGroupName: hubResourceGroup.name
    vnetName: hubVirtualNetwork.outputs.name
    networkingResourceGroupName: hubVirtualNetwork.outputs.resourceGroupName
    privateEndpointSubnetId: privateEndpointSubnetId                              // required for StandardV2
    privateEndpointName: apimPrivateEndpointName                                  // required for StandardV2
    privateEndpointNetworkInterfaceName: apimPrivateEndpointNetworkInterfaceName  // required for StandardV2
    diagnosticSettings: logAnalyticsDiagnosticSettings
    deploySample: deploySample
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure API Center
module apiCenter './api/apicenter.bicep' = if (deployApiCenter) {
  name: 'apiCenterDeployment'
  scope: apimResourceGroup
  params: {
    location: location
    apiCenterName: apiCenterName
    apimName: apiManagement.?outputs.name
    tags: tags
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


output hubResourceGroupName string = hubResourceGroup.name
output hubVirtualNetworkId string = hubVirtualNetwork.outputs.id
#disable-next-line BCP318
output azureFirewallId string = deployAzureFirewall ? azureFirewall.outputs.resourceId : azureFirewallExisting.id
#disable-next-line BCP318
output azureFirewallPrivateIp string = deployAzureFirewall ? azureFirewall.outputs.privateIp : contains(azureFirewallExisting.properties, 'ipConfigurations') ? azureFirewallExisting.properties.ipConfigurations[0].properties.privateIPAddress : ''
#disable-next-line BCP318
output appGatewayId string = appGateway.outputs.id
