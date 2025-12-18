@description('App service prefix.')
param appName string

@description('App service location.')
param location string = resourceGroup().location

@description('Name of the App service plan')
param appServicePlanName string

@description('Name of the App service environment. Optional')
param appServiceEnvironmentName string

@description('Enable Always-on of App service.')
param alwaysOn bool = true

@description('PHP version of App service.')
param phpVersion string = '5.6'

@description('.NET Framework version of App service.')
param netFrameworkVersion string = 'v8.0'

@description('The URL for the GitHub repository that contains the project to deploy.')
param repoURL string

@description('The branch of the GitHub repository to use.')
param branch string = 'master'

@description('The Application Insights connection string to use.')
param applicationInsightsConnectionString string 

@description('The IP security restrictions')
param ipSecurityRestrictions array

@description('Tags to be applied to the resource')
param tags object

@description('Additional appSettings to be applied')
param appSettings array

resource appServiceEnvironment 'Microsoft.Web/hostingEnvironments@2023-12-01' existing = if (!empty(appServiceEnvironmentName)) { 
  name: appServiceEnvironmentName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' existing = {
  name: appServicePlanName
}


@description('Combined array of all application settings.')
var allAppSettings = concat( appSettings, [
  {
    name: 'VNET_ROUTE_ALL'
    value: empty(appServiceEnvironment) ? '0' : '1'
  }
  { 
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    #disable-next-line BCP318
    value: (!empty(applicationInsightsConnectionString) ? applicationInsightsConnectionString : null)
  }
  {
    name: 'APPINSIGHTS_PROFILERFEATURE_VERSION'
    value: (!empty(applicationInsightsConnectionString) ? '1.0.0' : null) 
  }
  {
    name: 'APPINSIGHTS_SNAPSHOTFEATURE_VERSION'
    value: (!empty(applicationInsightsConnectionString) ? '1.0.0' : null) 
  }
  {
    name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: (!empty(applicationInsightsConnectionString) ? '~2' : null) 
  }
  {
    name: 'DiagnosticServices_EXTENSION_VERSION'
    value: (!empty(applicationInsightsConnectionString) ? '~3' : null) 
  }
  {
    name: 'InstrumentationEngine_EXTENSION_VERSION'
    value: (!empty(applicationInsightsConnectionString) ? 'disabled' : null) 
  }
  {
    name: 'SnapshotDebugger_EXTENSION_VERSION'
    value: (!empty(applicationInsightsConnectionString) ? 'disabled' : null) 
  }
  {
    name: 'XDT_MicrosoftApplicationInsights_BaseExtensions'
    value: (!empty(applicationInsightsConnectionString) ? 'disabled' : null) 
  }
  {
    name: 'XDT_MicrosoftApplicationInsights_Java'
    value: (!empty(applicationInsightsConnectionString) ? '1' : null) 
  }
  {
    name: 'XDT_MicrosoftApplicationInsights_Mode'
    value: (!empty(applicationInsightsConnectionString) ? 'recommended' : null) 
  }
  {
    name: 'XDT_MicrosoftApplicationInsights_NodeJS'
    value: (!empty(applicationInsightsConnectionString) ? '1' : null) 
  }
  {
    name: 'XDT_MicrosoftApplicationInsights_PreemptSdk'
    value: (!empty(applicationInsightsConnectionString) ? 'disabled' : null) 
  }
])


resource site 'Microsoft.Web/sites@2024-11-01' = {
  name: appName
  location: location
  tags: !empty(tags) ? tags : null
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      phpVersion: phpVersion
      netFrameworkVersion: netFrameworkVersion
      alwaysOn: alwaysOn
      appSettings: allAppSettings
      minTlsVersion: '1.2'
      use32BitWorkerProcess: false
      ftpsState: 'Disabled'
      remoteDebuggingEnabled: false
      http20Enabled: true
      ipSecurityRestrictions: !empty(ipSecurityRestrictions) ? ipSecurityRestrictions : null
      loadBalancing: 'LeastResponseTime'
    }
    serverFarmId: appServicePlan.id
    clientAffinityEnabled: false
    hostingEnvironmentProfile: {
      id: empty(appServiceEnvironment) ? null : appServiceEnvironment.id
    }
    publicNetworkAccess: 'Enabled'
    httpsOnly: true
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource sourceControl 'Microsoft.Web/sites/sourcecontrols@2024-11-01' = if (!empty(repoURL)) {
  parent: site
  name: 'web'
  properties: {
    repoUrl: repoURL
    branch: !empty(branch) ? branch : 'main'
    isManualIntegration: true
  }
}


output id string = site.id
output name string = site.name
output managedIdentityPrincipalId string = site.identity.principalId

