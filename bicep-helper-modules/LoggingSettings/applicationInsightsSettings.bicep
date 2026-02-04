param dateTime string = utcNow()
param applicationInsightsSettings {
  applicationInsightsName: string
  logAnalyticsName: string
  apiManagementServiceName: string
  serviceBusNamespaceName: string
  servicesBusSku: 'Basic' | 'Premium' | 'Standard'
  storageAccountName: string
}

// Log analytics workspace
module logAnalyticsWorkspace '../../bicep-helper-modules/LogAnalyticsWorkspace.bicep' =  {
  name: 'LogAnalytics-Main-${dateTime}'
  params: {
    logAnalyticsname: applicationInsightsSettings.logAnalyticsName
  }
}

// Application insights
module ai '../../bicep-registry-modules/avm/res/insights/component/main.bicep' ={
  name:'ApplicationInsights-${dateTime}'
  params: {
    name: applicationInsightsSettings.applicationInsightsName
    workspaceResourceId: logAnalyticsWorkspace.outputs.logAnalyticsResourceId
  }
}

module applicationInsightsAPIMSettings '../../bicep-registry-modules/avm/res/api-management/service/logger/main.bicep' = {
  name: 'ApplicationInsightsAPIMSettings-${dateTime}'
  params: {
    name: 'applicationInsightsAPIMLogger'
    apiManagementServiceName: applicationInsightsSettings.apiManagementServiceName
    credentials: {
      instrumentationKey: ai.outputs.instrumentationKey
    }
    targetResourceId: ai.outputs.resourceId
    type: 'applicationInsights'
    description: 'Application Insights logger'
  }
}
module serviceBus_applicationInsights_config '../../bicep-registry-modules/avm/res/service-bus/namespace/main.bicep' = {
  name: 'ServiceBus-ApplicationInsights-${dateTime}'
  params: {
    name: applicationInsightsSettings.serviceBusNamespaceName
    skuObject: {
      name: applicationInsightsSettings.servicesBusSku
    }
    diagnosticSettings: [
      {
        name: 'ServiceBusDiagnosticSetting'
        workspaceResourceId: logAnalyticsWorkspace.outputs.logAnalyticsResourceId
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: false
          }
        ]
        logCategoriesAndGroups: [
          {
            category: 'OperationalLogs'
            enabled: true
          }
        ]
      }
    ]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: applicationInsightsSettings.storageAccountName
}
resource storage_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'StorageDiagnosticSetting'
  scope: storageAccount
  properties: {
    workspaceId: logAnalyticsWorkspace.outputs.logAnalyticsResourceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output applicationInsightsResourceId string = ai.outputs.resourceId
output applicationInsightsInstrumentationKey string = ai.outputs.instrumentationKey
