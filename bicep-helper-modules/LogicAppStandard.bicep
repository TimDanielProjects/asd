param location string = resourceGroup().location
param dateTime string = utcNow()
param NodiniteLoggingEnabled string
param ApplicationInsightsLoggingEnabled string
param organisationSuffix string
param environmentSuffix string
param sharedResources {
  sharedResourceGroupName: string
  sharedAppServicePlanName: string
  sharedAppServicePlanResourceId: string
  sharedEventHubsNamespaceName: string
  sharedEventHubsNamespaceResourceId: string
  sharedAPIMName: string
  sharedServiceBusNamespaceName: string
  sharedServiceBusNamespaceResourceId: string
  sharedKeyVaultName: string
  sharedFunctionAppName: string
  sharedApplicationInsightsName: string
}
param storageAccount {
  resourceId: string
  name: string
}
param logicAppName string
var nodiniteLoggingSettings = {
  nodiniteLogging_StorageAccountName: toLower('${organisationSuffix}intnodinitelog${environmentSuffix}') // Storage account name for Nodinite logging
  nodiniteLogging_functionLoggingContainerName: 'function-nodinitelogevents' // Blob storage container name for Nodinite logging (Function Apps)
}
resource nodiniteStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: nodiniteLoggingSettings.nodiniteLogging_StorageAccountName
  scope: resourceGroup(sharedResources.sharedResourceGroupName)
}
resource logicAppStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccount.name
}
resource sharedAppInsights 'Microsoft.Insights/components@2020-02-02' existing = if (ApplicationInsightsLoggingEnabled == 'true') {
  name: sharedResources.sharedApplicationInsightsName
  scope: resourceGroup(sharedResources.sharedResourceGroupName)
}
var logicAppStandardSettings = {
  //These are environment variables that will be located in "Environment variables" in the Logic App
//*****************************************************************************************************************

  APP_KIND: 'workflowApp'
  AzureFunctionsJobHost__extensionBundle__id: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
  AzureFunctionsJobHost__extensionBundle__version: '[1.*, 2.0.0)'
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'node'
  WEBSITE_NODE_DEFAULT_VERSION: '~20'
  WEBSITE_RUN_FROM_PACKAGE: '1'
  subscriptionId: subscription().subscriptionId
  resourceGroupName: resourceGroup().name
  sharedResourceGroupName: sharedResources.sharedResourceGroupName
  location: location

  // Required storage settings for Logic App Standard runtime
  AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${logicAppStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${logicAppStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
  WEBSITE_CONTENTSHARE: toLower(logicAppName)
  AzureWebJobsSecretStorageType: 'Blob'

  // Nodinite logging parameters (these will be passed to the Logic App, regardless of the logging method)
  NodiniteFunctionLoggingContainerName: nodiniteLoggingSettings.nodiniteLogging_functionLoggingContainerName
  NodiniteStorageAccountConnectionString: 'DefaultEndpointsProtocol=https;AccountName=${nodiniteLoggingSettings.nodiniteLogging_StorageAccountName};AccountKey=${nodiniteStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
}

// Only Nodinite logging enabled
module logicAppStandardWithNodinite './LogicApp_Modules/LogicAppStandard_NodiniteOnly.bicep' = if(NodiniteLoggingEnabled == 'true' && ApplicationInsightsLoggingEnabled == 'false'){
  name: 'LogicAppStandard-NodiniteOnly-${dateTime}'
  params: {
    location: location
    logicAppName: logicAppName
    serverFarmResourceId: sharedResources.sharedAppServicePlanResourceId
    logicAppSettings: logicAppStandardSettings
    sharedResources: sharedResources
  }
}

// only Application Insights logging enabled
module logicAppStandardWithApplicationInsights './LogicApp_Modules/LogicAppStandard_AppInsightsOnly.bicep' = if(ApplicationInsightsLoggingEnabled == 'true' && NodiniteLoggingEnabled == 'false'){
  name: 'LogicAppStandard-AppInsightsOnly-${dateTime}'
  params: {
    location: location
    logicAppName: logicAppName
    serverFarmResourceId: sharedResources.sharedAppServicePlanResourceId
    logicAppSettings: logicAppStandardSettings
    applicationInsightResourceId: sharedAppInsights.id
  }
}

// All logging enabled
module logicAppStandardWithBothLoggingEnabled './LogicApp_Modules/LogicAppStandard_BothLogging.bicep' = if(NodiniteLoggingEnabled == 'true' && ApplicationInsightsLoggingEnabled == 'true'){
  name: 'LogicAppStandard-BothLogging-${dateTime}'
  params: {
    location: location
    logicAppName: logicAppName
    serverFarmResourceId: sharedResources.sharedAppServicePlanResourceId
    logicAppSettings: logicAppStandardSettings
    applicationInsightResourceId: sharedAppInsights.id
    sharedResources: sharedResources
  }
}

// No logging enabled
module logicAppStandardWithNoLoggingEnabled './LogicApp_Modules/LogicAppStandard_NoLogging.bicep' = if(NodiniteLoggingEnabled == 'false' && ApplicationInsightsLoggingEnabled == 'false'){
  name: 'LogicAppStandard-NoLogging-${dateTime}'
  params: {
    location: location
    logicAppName: logicAppName
    serverFarmResourceId: sharedResources.sharedAppServicePlanResourceId
    logicAppSettings: logicAppStandardSettings
  }
}

// Variables to handle outputs safely
var deployedLogicApp = NodiniteLoggingEnabled == 'true' && ApplicationInsightsLoggingEnabled == 'false' ? logicAppStandardWithNodinite : (ApplicationInsightsLoggingEnabled == 'true' && NodiniteLoggingEnabled == 'false' ? logicAppStandardWithApplicationInsights : (NodiniteLoggingEnabled == 'true' && ApplicationInsightsLoggingEnabled == 'true' ? logicAppStandardWithBothLoggingEnabled : logicAppStandardWithNoLoggingEnabled))

// Output the correct systemAssignedPrincipalId based on which module was deployed
output logicAppName string = logicAppName
output systemAssignedPrincipalId string = deployedLogicApp.outputs.systemAssignedPrincipalId
output logicAppId string = deployedLogicApp.outputs.logicAppId
output logicAppUrl string = deployedLogicApp.outputs.logicAppUrl
