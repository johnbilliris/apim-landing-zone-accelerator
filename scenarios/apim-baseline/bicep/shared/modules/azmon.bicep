targetScope='resourceGroup'

// Parameters
@description('Azure location to which the resources are to be deployed')
param location string

@description('Log Analytics workspace id')
param logAnalyticsWorkspaceId string

@description('The resource name of the Application Insights instance that the API Management service will log to.')
param applicationInsightsName string = 'appi-apim'

@description('Tags to be applied to all resources')
param tags object = {}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Resources

resource appInsights 'Microsoft.Insights/components@2020-02-02' = if (!empty(applicationInsightsName)) {
  name: applicationInsightsName
  location: location
  tags: !empty(tags) ? tags : null
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtension'
    RetentionInDays: 90
    #disable-next-line BCP037
    CustomMetricsOptedInType: 'WithDimensions'
  }
}

output appInsightsConnectionString string? = appInsights.?properties.?ConnectionString
output appInsightsName string? = appInsights.?name
output appInsightsId string? = appInsights.?id
output appInsightsInstrumentationKey string? = appInsights.?properties.?InstrumentationKey
