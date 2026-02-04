param location string
param functionAppName string
param serverFarmResourceId string
param functionAppSettings object
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

var baseAppSettings = [for item in items(functionAppSettings): {
  name: item.key
  value: item.value
}]

resource functionAppWithAppInsights 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: serverFarmResourceId
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      ftpsState: 'Disabled'
      netFrameworkVersion: 'v9.0'
      alwaysOn: true
      minTlsVersion: '1.2'
      http20Enabled: true
      scmMinTlsVersion: '1.2'
      use32BitWorkerProcess: false
      remoteDebuggingEnabled: false
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: true
      cors: {
        allowedOrigins: ['*']
        supportCredentials: false
      }
      appSettings: concat(baseAppSettings, appInsightsSettings)
    }
  }
}

output functionAppName string = functionAppWithAppInsights.name
output functionAppId string = functionAppWithAppInsights.id
output systemAssignedPrincipalId string = functionAppWithAppInsights.identity.principalId
output defaultHostname string = functionAppWithAppInsights.properties.defaultHostName
