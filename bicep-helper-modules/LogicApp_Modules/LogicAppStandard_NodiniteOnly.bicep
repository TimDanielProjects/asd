param location string
param logicAppName string
param serverFarmResourceId string
param logicAppSettings object
param sharedResources object

var baseAppSettings = [for item in items(logicAppSettings): {
  name: item.key
  value: item.value
}]

resource logicAppStandardWithNodinite 'Microsoft.Web/sites@2023-01-01' = {
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

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'nodiniteDiagnosticSetting'
  scope: logicAppStandardWithNodinite
  properties: {
    eventHubAuthorizationRuleId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${sharedResources.sharedResourceGroupName}/providers/microsoft.eventhub/namespaces/${sharedResources.sharedEventHubsNamespaceName}/authorizationrules/RootManageSharedAccessKey'
    eventHubName: 'nodinitelogevents'
    metrics: [
      {
        category: 'AllMetrics'
        enabled: false
      }
    ]
    logs: [
      {
        category: 'WorkflowRuntime'
        enabled: true
      }
    ]
  }
}

output logicAppName string = logicAppStandardWithNodinite.name
output logicAppId string = logicAppStandardWithNodinite.id
output systemAssignedPrincipalId string = logicAppStandardWithNodinite.identity.principalId
output logicAppUrl string = 'https://${logicAppStandardWithNodinite.properties.defaultHostName}'
