param location string
param logicAppName string
param serverFarmResourceId string
param logicAppSettings object
param applicationInsightResourceId string
param sharedResources object

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

resource logicAppStandardWithBothLogging 'Microsoft.Web/sites@2023-01-01' = {
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

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'nodiniteDiagnosticSetting'
  scope: logicAppStandardWithBothLogging
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

output logicAppName string = logicAppStandardWithBothLogging.name
output logicAppId string = logicAppStandardWithBothLogging.id
output systemAssignedPrincipalId string = logicAppStandardWithBothLogging.identity.principalId
output logicAppUrl string = 'https://${logicAppStandardWithBothLogging.properties.defaultHostName}'
