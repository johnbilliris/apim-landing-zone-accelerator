
@description('The location of all resources')
param location string = resourceGroup().location

@description('Resource ID of the subnet for the VM network interface.')
param subnetId string

@description('The name of the Virtual Machine')
param vmName string = 'vm1'

@description('The size of the Virtual Machine')
param vmSize string = 'Standard_D2s_v3'

@description('The administrator username')
param adminUsername string

@description('The administrator password')
@secure()
param adminPassword string

@description('Tags to apply to all resources.')
param tags object = {}


@description('Specifies the storage account type for OS and data disk.')
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
  'UltraSSD_LRS'
])
param osDiskStorageAccountType string = 'Standard_LRS'

resource vmNic 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: '${vmName}-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-smalldisk'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
         managedDisk: {
          storageAccountType: osDiskStorageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output id string = vm.id
output resourceGroupName string = resourceGroup().name
output name string = vm.name
output location string = vm.location
