param location string
param logicAppName string
param serverFarmResourceId string
param logicAppSettings object
param applicationInsightResourceId string

var appInsightsSettings = [
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: reference(applicationInsightResourceId, '2020-02-02').InstrumentationKey
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: reference(applicationInsightResourceId, '2020-02-02').ConnectionString
  }
]

var baseAppSettings = [for item in items(logicAppSettings): {
  name: item.key
  value: item.value
}]

resource logicAppStandardWithAppInsights 'Microsoft.Web/sites@2023-01-01' = {
  name: logicAppName
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: serverFarmResourceId
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      functionsRuntimeScaleMonitoringEnabled: false
      ftpsState: 'Disabled'
      appSettings: concat(baseAppSettings, appInsightsSettings)
    }
  }
}

output logicAppName string = logicAppStandardWithAppInsights.name
output logicAppId string = logicAppStandardWithAppInsights.id
output systemAssignedPrincipalId string = logicAppStandardWithAppInsights.identity.principalId
output logicAppUrl string = 'https://${logicAppStandardWithAppInsights.properties.defaultHostName}'
