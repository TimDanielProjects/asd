param location string
param logicAppName string
param serverFarmResourceId string
param logicAppSettings object

var baseAppSettings = [for item in items(logicAppSettings): {
  name: item.key
  value: item.value
}]

resource logicAppStandardNoLogging 'Microsoft.Web/sites@2023-01-01' = {
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
      appSettings: baseAppSettings
    }
  }
}

output logicAppName string = logicAppStandardNoLogging.name
output logicAppId string = logicAppStandardNoLogging.id
output systemAssignedPrincipalId string = logicAppStandardNoLogging.identity.principalId
output logicAppUrl string = 'https://${logicAppStandardNoLogging.properties.defaultHostName}'
