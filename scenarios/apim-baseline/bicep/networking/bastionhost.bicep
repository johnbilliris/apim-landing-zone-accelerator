@description('Location.')
param location string = resourceGroup().location

@description('Tags to be applied to the resource')
param tags object

@description('Name of the Azure Bastion host resource.')
param hostName string

@description('Name of the public IP address for the Bastion host.')
param publicIpName string

@description('SKU name for the Bastion host. Standard recommended.')
param skuName string = 'Standard'

@description('Resource ID of the virtual network for Bastion.')
param virtualNetworkId string

@description('Resource ID of the Log Analytics workspace.')
param workspaceResourceId string

@description('Array of diagnostic settings for monitoring.')
param diagnosticSettings array = []


resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: publicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
  tags: tags
}


module bastionHost 'br/public:avm/res/network/bastion-host:0.8.0' = {
  name: 'bastionHostDeployment'
  params: {
    // Required parameters
    name: hostName
    virtualNetworkResourceId: virtualNetworkId
    // Non-required parameters
    bastionSubnetPublicIpResourceId: bastionPublicIP.id
    // Enable diagnostics to send to Log Analytics workspace
    diagnosticSettings:  [
        for (diagnosticSetting, index) in (diagnosticSettings ?? []): {
        name: '${diagnosticSetting.?namePrefix}${bastionPublicIP.name}-${diagnosticSetting.?destinationSuffix}'
        workspaceResourceId: workspaceResourceId
        logCategoriesAndGroups: diagnosticSetting.?logCategoriesAndGroups
      }
    ]
    disableCopyPaste: false
    enableIpConnect: false
    enableShareableLink: false
    enableKerberos: false
    enableSessionRecording: false
    enablePrivateOnlyBastion: false
    location: location
    scaleUnits: 2
    skuName: skuName
    tags: tags
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output id string = bastionHost.outputs.resourceId
output resourceGroupName string = resourceGroup().name
output name string = bastionHost.outputs.name
output location string = bastionHost.outputs.location
