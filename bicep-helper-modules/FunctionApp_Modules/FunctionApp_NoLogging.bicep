param location string
param functionAppName string
param serverFarmResourceId string
param functionAppSettings object

var baseAppSettings = [for item in items(functionAppSettings): {
  name: item.key
  value: item.value
}]

resource functionAppNoLogging 'Microsoft.Web/sites@2023-01-01' = {
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
      appSettings: baseAppSettings
    }
  }
}

output functionAppName string = functionAppNoLogging.name
output functionAppId string = functionAppNoLogging.id
output systemAssignedPrincipalId string = functionAppNoLogging.identity.principalId
output defaultHostname string = functionAppNoLogging.properties.defaultHostName
