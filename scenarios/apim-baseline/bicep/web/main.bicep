@description('App service environment location.')
param location string = resourceGroup().location

@description('Tags to be applied to all resources.')
param tags object = {}

@description('Required. Name of ASEv3.')
param aseName string

@description('Required. Dedicated host count of ASEv3.')
param dedicatedHostCount int = 0

@description('Required. Zone redundant of ASEv3.')
param zoneRedundant bool = false

@description('Required. Specifies which endpoints to serve internally in the Virtual Network for the App Service Environment: \'None\', \'Publishing\', \'Web\', \'Web, Publishing\'')
@allowed([
  'None', 'Publishing', 'Web', 'Web, Publishing'
])
param internalLoadBalancingMode string = 'Web, Publishing'

@description('Required. The subnet ID for the App Service Environment.')
param subnetId string
@description('Whether to create private DNS zone for ASE.')
param createPrivateDNS bool = true
@description('Resource group for the private DNS zone.')
param privateDnsResourceGroupName string = ''

@description('The Application Insights instance connection string.')
param applicationInsightsConnectionString string = ''

@description('Resource ID of the Log Analytics workspace.')
param logAnalyticsWorkspaceId string


@description('Whether to deploy sample App Services.')
param deploySample bool = true
@description('Required. Array of App Services to be deployed within the ASE.')
param appServices array = [
  { 
    name: 'app-frontend'
    appServicePlanName: 'asp-asev3-frontend'
    properties: {
      repoURL: 'https://github.com/johnbilliris/app-service-web-dotnet-get-started.git'
      branch: 'main'
      netFrameworkVersion: 'v4.8'
    }
    appSettings: [
      {
        name: 'webpages:Version'
        value: '3.0.0.0'
      }
      {
        name: 'webpages:Enabled'
        value: 'false'
      }
      {
        name: 'ClientValidationEnabled'
        value: 'true'
      }
      {
        name: 'UnobtrusiveJavaScriptEnabled'
        value: 'true'
      }
      {
        name: 'ToDoApiUrl'
        value: 'https://app-backend.ase-ae-inte-dev-01.appserviceenvironment.net/'
      } 
    ]
  }
  { 
    name: 'app-backend'
    appServicePlanName: 'asp-asev3-backend'
    properties: {
      repoURL: 'https://github.com/johnbilliris/dotnet-core-api.git'
      branch: 'master'
      netFrameworkVersion: 'v8.0'
    }
    appSettings: [
      {
        name: 'AllowedHosts'
        value: '*'
      }
      {
        name: 'ResponseMode'
        value: 'Variable'
      }
      {
        name: 'ResponseDelay'
        value: '300'
      }
      {
        name: 'Create60SecondDelayOn'
        value: '300'
      }
    ]
  }
]

module ase 'appServiceEnvironment.bicep' = {
  name: 'appServiceEnvironmentDeployment'
  params: {
    aseName: aseName
    location: location
    dedicatedHostCount: dedicatedHostCount
    zoneRedundant: zoneRedundant
    internalLoadBalancingMode: internalLoadBalancingMode
    subnetId: subnetId
    tags: tags
    createPrivateDNS: createPrivateDNS
    privateDnsResourceGroupName: privateDnsResourceGroupName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

@description('Array of App Service Plan names from appServices.')
var appServicePlans = map(appServices, item => item.appServicePlanName)
@description('Unique list of App Service Plans to deploy.')
var uniqueAppServicePlans = union(appServicePlans, appServicePlans)
module appServicePlan 'appserviceplan.bicep' = [for asp in uniqueAppServicePlans: if (deploySample) {
  name: 'appServicePlan-${asp}-Deployment'
  params: {
    appServicePlanName : asp
    appServiceEnvironmentName: ase.outputs.name
    location: location
    appServicePlanCapacity: 1
    tags: tags
  }
}]

module site 'appservice.bicep' = [for appService in appServices: if (deploySample) {
  name: 'appService-${appService.name}-Deployment'
  dependsOn: [
    appServicePlan
  ] 
  params: {
    appName: appService.name
    location: location
    tags: tags
    appServicePlanName: appService.appServicePlanName
    appServiceEnvironmentName: ase.outputs.name
    repoURL: appService.properties.repoURL
    branch: appService.properties.branch
    netFrameworkVersion: appService.properties.netFrameworkVersion
    applicationInsightsConnectionString: applicationInsightsConnectionString
    ipSecurityRestrictions: []
    appSettings: appService.appSettings
  }
}]


output name string = ase.outputs.name
output id string = ase.outputs.id
output resourceGroupName string = ase.outputs.resourceGroupName
output location string = ase.outputs.location

