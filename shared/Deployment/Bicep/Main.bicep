@minLength(3)
param integrationId string
param organisationSuffix string
param environmentSuffix string
param regionSuffix string
param NodiniteLoggingEnabled string
param ApplicationInsightsLoggingEnabled string
param location string = az.resourceGroup().location
param dateTime string = utcNow()
// Variables
var resourceBaseName = toLower('${organisationSuffix}-int-${integrationId}')
var resourceEnding = toLower('${regionSuffix}-${environmentSuffix}')
var keyVaultName = '${resourceBaseName}-kv-${resourceEnding}'
var fixedKeyVaultName = '${resourceBaseName}-kv-${toLower(environmentSuffix)}'
var sharedResourceGroup = { name: resourceGroup().name }
var sharedServiceBus = { 
  namespaceName: '${resourceBaseName}-sbns-${resourceEnding}'
  sku: 'Standard'
 }
var sharedEventHub = { namespaceName: '${resourceBaseName}-ehns-${resourceEnding}' }
var sharedKeyVault = { name: length(keyVaultName) > 24 ? fixedKeyVaultName : keyVaultName }
var sharedLogicApp = { name: '${resourceBaseName}-la-${resourceEnding}' }
var sharedFunctionApp = { name: '${resourceBaseName}-fa-${resourceEnding}' }
var sharedStorageAccount = { name: 'st${uniqueString(organisationSuffix,integrationId,environmentSuffix)}' }
var sharedLogAnalytics = { name: '${resourceBaseName}-law-${resourceEnding}' }
var sharedAppInsights = { name: '${resourceBaseName}-ai-${resourceEnding}' }
var sharedDataFactory = { name: '${resourceBaseName}-df-${resourceEnding}'}

// Shared resources
var sharedApiManagement = {
  name: '${resourceBaseName}-apim-${resourceEnding}'
  publisherEmail: 'support@temp.se' //Make sure to add the correct e-mail addresses
  publisherName: 'temp' //Make sure to add the correct name
  tier: environmentSuffix != 'prod' ? 'Developer' : 'BasicV2'
  skuCapacity: 1
}
var sharedAppServicePlanLAStandard = {
  name: '${resourceBaseName}-aspla-${resourceEnding}'
  skuName: 'WS1'
  skuCapacity: 1
  elasticScaleEnabled: true
  maximumScaleBurst: 4
}
var nodiniteLoggingSettings = {
  nodiniteLogging_StorageAccountName: toLower('${organisationSuffix}intnodinitelog${environmentSuffix}') // Storage account name for Nodinite logging
  nodiniteLogging_functionLoggingContainerName: 'function-nodinitelogevents' // Blob storage container name for Nodinite logging (Function Apps)
  nodiniteLogging_OtherLoggingContainerName: 'nodinitelogevents' // Blob storage blob name for Nodinite logging (Other resources I.E. APIM)
  nodiniteLogging_EventHubName: 'nodinitelogevents' // Event Hub name for Nodinite logging
  nodiniteLogging_EventHub_CheckpointCaptureContainerName: 'eventhub-nodinitelogevents-checkpoint' // Blob storage container name for Nodinite logging (Event Hub Checkpoint and Capture)
}

//Existing resources (Created in "Setup.bicep")
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: sharedKeyVault.name
  scope: resourceGroup(sharedResourceGroup.name)
}
// Storage account
module StorageAccount '../../../bicep-helper-modules/StorageAccount.bicep' = {
  name: 'StorageAccount-Main-${dateTime}'
  params: {
    storageAccountName: sharedStorageAccount.name
  }
}

//Service bus namespace
module servicebusNamespace '../../../bicep-helper-modules/ServiceBusNamespace.bicep' = {
  name: 'ServiceBusNamespace-Main-${dateTime}'
  params: {
    location: location
    serviceBus: {
      namespaceName: sharedServiceBus.namespaceName
      sku: sharedServiceBus.sku
      resourceGroupName: sharedResourceGroup.name
    }
  }
}

// Data Factory
module dataFactory '../../../bicep-helper-modules/DataFactory.bicep' = {
  name: 'DataFactory-Main-${dateTime}'
  params: {
    DataFactoryName: sharedDataFactory.name
  }
}

// APIM
module apim '../../../bicep-helper-modules/APIM.bicep' = {
  name: 'APIM-Main-${dateTime}'
  params: {
    location: location
    APIManagementService: {
      Name: sharedApiManagement.name
      PublisherEmail: sharedApiManagement.publisherEmail
      PublisherName: sharedApiManagement.publisherName
      APIMTier: sharedApiManagement.tier
    }
    keyVaultName: sharedKeyVault.name
  }
}

module NodiniteLogSettings '../../../bicep-helper-modules/LoggingSettings/NodiniteSettings.bicep' = if (NodiniteLoggingEnabled == 'true') {
  name: 'NodiniteLogSettings-Main-${dateTime}'
  params: {
    environmentSuffix: environmentSuffix
    NodiniteLoggingSettings: {
      nodiniteBlobContainerName: nodiniteLoggingSettings.nodiniteLogging_OtherLoggingContainerName
      nodiniteStorageAccountName: nodiniteLoggingSettings.nodiniteLogging_StorageAccountName
      nodiniteFunctionBlobContainerName: nodiniteLoggingSettings.nodiniteLogging_functionLoggingContainerName
      EventHubSettings:{
      captureDescriptionDestinationBlobContainer: nodiniteLoggingSettings.nodiniteLogging_EventHub_CheckpointCaptureContainerName
      captureDescriptionEnabled: true
      eventHubNamespaceName: sharedEventHub.namespaceName
      mmessageRetentionInDays: 7
      nodiniteLoggingEventHubName: nodiniteLoggingSettings.nodiniteLogging_EventHubName
      partitioncount: 1
      }
    }
    APIMSettings: {
      name: apim.outputs.name
      publisherEmail: sharedApiManagement.publisherEmail
      publisherName: sharedApiManagement.publisherName
      tier: sharedApiManagement.tier
    }
  }
}
module applicationInsightsSettings '../../../bicep-helper-modules/LoggingSettings/applicationInsightsSettings.bicep' = if (ApplicationInsightsLoggingEnabled == 'true') {
  name: 'ApplicationInsightsSettings-Main-${dateTime}'
  dependsOn: [
    servicebusNamespace
    apim
  ]
  params: {
    applicationInsightsSettings: {
      apiManagementServiceName: sharedApiManagement.name
      applicationInsightsName: sharedAppInsights.name
      logAnalyticsName: sharedLogAnalytics.name
      serviceBusNamespaceName: sharedServiceBus.namespaceName
      servicesBusSku: sharedServiceBus.sku
      storageAccountName: sharedStorageAccount.name
    }
  }
}

//app service plan for logic app standard
module aspLAStandard '../../../bicep-helper-modules/appServicePlan.bicep' = {
  name: 'appServicePlanLAStandard-Main-${dateTime}'
  params: {
    location: location
    appServicePlan: {
      name: sharedAppServicePlanLAStandard.name
      skuName: sharedAppServicePlanLAStandard.skuName
      skuCapacity: sharedAppServicePlanLAStandard.skuCapacity
      elasticScaleEnabled: sharedAppServicePlanLAStandard.elasticScaleEnabled
      maximumScaleBurst: sharedAppServicePlanLAStandard.maximumScaleBurst
    }
  }
}


//RBAC for resources
module RBAC '../../../bicep-helper-modules/AccessControlWithRBAC/RBAC.bicep' = {
  name: 'RBAC-Main-${dateTime}'
  dependsOn: [
    keyVault
  ]
  params: {
    RBACSettings: {
      apimSettings: {
        name: sharedApiManagement.name
        roleAssignments: [
        ]
      }
      serviceBusNamespaceSettings: {
        namespaceName: sharedServiceBus.namespaceName
        roleAssignments: [
        ]
      }
      keyVaultSettings: {
        keyVaultName: sharedKeyVault.name
        roleAssignments: [
          {
            principalId: apim.outputs.principalId
            roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6'
            //'Key Vault Secrets User'
          }
        ]
      }
      storageAccountSettings: {
        storageAccountName: StorageAccount.outputs.name
        roleAssignments: [
        ]
      }
    }
  }
}

output functionAppName string = sharedFunctionApp.name
output logicAppStandardName string = sharedLogicApp.name
