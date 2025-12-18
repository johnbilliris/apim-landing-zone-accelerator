targetScope = 'subscription'

// pull resource abbreviations from a common JSON file
@description('Resource abbreviations loaded from JSON configuration file.')
var resourceAbbreviations = loadJsonContent('abbreviations.json')

output logAnalyticsWorkspaces array = [
  {
    name: 'NDA-COR-AWG-SENTINEL-PROD'
    resourceGroupName: 'nda-cor-arg-sentinel-prod'
    subscriptionId : subscription().subscriptionId
    type: 'sentinel'
    diagnosticSettingsEnabled: true
    diagnosticSetting: {
      namePrefix: resourceAbbreviations.diagnosticSettings
      logCategoriesAndGroups: [
        {
          categoryGroup: 'allLogs'
        }
      ]
    }
  }
  {
    name: 'LA-AE-MGMT-01'
    resourceGroupName: 'rg-ae-mgmt-oms-01'
    subscriptionId : subscription().subscriptionId
    type: 'law'
    diagnosticSettingsEnabled: true
    diagnosticSetting: {
      namePrefix: resourceAbbreviations.diagnosticSettings
      metricCategories: [
        {
          category: 'AllMetrics'
        }
      ]
    }
  }
]


output applicationInsights array = [
  {
    name: 'appi-ae-mgmt-01'
    resourceGroupName: 'rg-ae-mgmt-oms-01'
    subscriptionId : subscription().subscriptionId
  }
]
