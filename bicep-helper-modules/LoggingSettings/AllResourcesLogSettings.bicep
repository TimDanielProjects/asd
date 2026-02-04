param dateTime string = utcNow()
param organisationSuffix string
param environmentSuffix string
param logicAppName string
param NodiniteLoggingEnabled string
param ApplicationInsightsLoggingEnabled string
param storageAccount {
  resourceId: string
  name: string
}
param sharedResources {
  sharedAPIMName: string
  sharedAppServicePlanName: string
  sharedAppServicePlanResourceId: string
  sharedEventHubsNamespaceName: string
  sharedEventHubsNamespaceResourceId: string
  sharedFunctionAppName: string
  sharedKeyVaultName: string
  sharedServiceBusNamespaceName: string
  sharedServiceBusNamespaceResourceId: string
  sharedResourceGroupName: string
  sharedApplicationInsightsName: string
}

var nodiniteLoggingSettings = {
  nodiniteLogging_StorageAccountName: toLower('${organisationSuffix}intnodinitelog${environmentSuffix}') // Storage account name for Nodinite logging
  nodiniteLogging_functionLoggingContainerName: 'function-nodinitelogevents' // Blob storage container name for Nodinite logging (Function Apps)
  nodiniteLogging_OtherLoggingContainerName: 'nodinitelogevents' // Blob storage blob name for Nodinite logging (Other resources I.E. APIM)
  nodiniteLogging_EventHubName: 'nodinitelogevents' // Event Hub name for Nodinite logging
  nodiniteLogging_EventHub_CheckpointCaptureContainerName: 'eventhub-nodinitelogevents-checkpoint' // Blob storage container name for Nodinite logging (Event Hub Checkpoint and Capture)
}

resource nodiniteStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = if (NodiniteLoggingEnabled == 'true') {
  name: nodiniteLoggingSettings.nodiniteLogging_StorageAccountName
  scope: resourceGroup(sharedResources.sharedResourceGroupName)
}

resource sharedAppInsights 'Microsoft.Insights/components@2020-02-02' existing = if (ApplicationInsightsLoggingEnabled == 'true') {
  name: sharedResources.sharedApplicationInsightsName
  scope: resourceGroup(sharedResources.sharedResourceGroupName)
}
// THIS IS FOR CONFIGURING NODINITE LOGGING

module logicApp_Nodinite_config '../../bicep-registry-modules/avm/res/web/site/main.bicep' = if (NodiniteLoggingEnabled == 'true') {
  name: 'LogicAppNodinite-Site-${dateTime}'
  params: {
    name: logicAppName
    kind: 'functionapp,workflowapp'
    serverFarmResourceId: sharedResources.sharedAppServicePlanResourceId
    configs: [
      {
        name: 'appsettings'
        properties: {
          //Nodinite Settings
          NodiniteFunctionLoggingContainerName: nodiniteLoggingSettings.nodiniteLogging_functionLoggingContainerName
          NodiniteStorageAccountConnectionString: 'DefaultEndpointsProtocol=https;AccountName=${nodiniteLoggingSettings.nodiniteLogging_StorageAccountName};AccountKey=${nodiniteStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        storageAccountResourceId: storageAccount.resourceId
      }
    ]
    diagnosticSettings: [
      {
        name: 'nodiniteDiagnosticSetting'
        eventHubAuthorizationRuleResourceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${sharedResources.sharedResourceGroupName}/providers/microsoft.eventhub/namespaces/${sharedResources.sharedEventHubsNamespaceName}/authorizationrules/RootManageSharedAccessKey'
        eventHubName: 'nodinitelogevents'
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: false
          }
        ]
        logCategoriesAndGroups: [
          {
            category: 'WorkflowRuntime'
            enabled: true
          }
        ]
      }
    ]
  }
}

// THIS IS FOR CONFIGURING APPLICATION INSIGHTS LOGGING

module logicApp_applicationInsights_config '../../bicep-registry-modules/avm/res/web/site/config/main.bicep' = if (ApplicationInsightsLoggingEnabled == 'true') {
  name: 'logicAppApplicationInsightsConfig'
  params: {
    appName: logicAppName
    name: 'appsettings'
    applicationInsightResourceId: sharedAppInsights.id
    storageAccountResourceId: storageAccount.resourceId
    properties: {}
  }
}
