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
param appServicePlan {
  resourceId: string
}
param storageAccount {
  resourceId: string
  name: string
}
param functionAppParameters {
  functionAppName: string
}
// Variables
var functionAppName = functionAppParameters.functionAppName
var nodiniteLoggingSettings = {
  nodiniteLogging_StorageAccountName: toLower('${organisationSuffix}intnodinitelog${environmentSuffix}') // Storage account name for Nodinite logging
  nodiniteLogging_functionLoggingContainerName: 'function-nodinitelogevents' // Blob storage container name for Nodinite logging (Function Apps)
}

resource nodiniteStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: nodiniteLoggingSettings.nodiniteLogging_StorageAccountName
  scope: resourceGroup(sharedResources.sharedResourceGroupName)
}

resource sharedAppInsights 'Microsoft.Insights/components@2020-02-02' existing = if (ApplicationInsightsLoggingEnabled == 'true') {
  name: sharedResources.sharedApplicationInsightsName
  scope: resourceGroup(sharedResources.sharedResourceGroupName)
}

var functionAppEnvironmentSettings = {
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
  WEBSITE_RUN_FROM_PACKAGE: '1'
  WEBSITE_ENABLE_SYNC_UPDATE_SITE: 'true'
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey={listKeys(storageAccount.resourceId, \'2021-04-01\').keys[0].value}'
  AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey={listKeys(storageAccount.resourceId, \'2021-04-01\').keys[0].value}'
  WEBSITE_CONTENTSHARE: toLower(functionAppName)
  
  // Nodinite logging parameters (these will be passed to the Function App, regardless of the logging method)
  NodiniteFunctionLoggingContainerName: nodiniteLoggingSettings.nodiniteLogging_functionLoggingContainerName
  NodiniteStorageAccountConnectionString: 'DefaultEndpointsProtocol=https;AccountName=${nodiniteLoggingSettings.nodiniteLogging_StorageAccountName};AccountKey=${nodiniteStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
}

// Only Nodinite logging enabled
module functionAppWithNodinite './FunctionApp_Modules/FunctionApp_NodiniteOnly.bicep' = if(NodiniteLoggingEnabled == 'true' && ApplicationInsightsLoggingEnabled == 'false'){
  name: 'FunctionApp-NodiniteOnly-${dateTime}'
  params: {
    location: location
    functionAppName: functionAppName
    serverFarmResourceId: appServicePlan.resourceId
    functionAppSettings: functionAppEnvironmentSettings
    sharedResources: sharedResources
  }
}

// only Application Insights logging enabled
module functionAppWithApplicationInsights './FunctionApp_Modules/FunctionApp_AppInsightsOnly.bicep' = if(ApplicationInsightsLoggingEnabled == 'true' && NodiniteLoggingEnabled == 'false'){
  name: 'FunctionApp-AppInsightsOnly-${dateTime}'
  params: {
    location: location
    functionAppName: functionAppName
    serverFarmResourceId: appServicePlan.resourceId
    functionAppSettings: functionAppEnvironmentSettings
    applicationInsightResourceId: sharedAppInsights.id
  }
}

// All logging enabled
module functionAppWithBothLoggingEnabled './FunctionApp_Modules/FunctionApp_BothLogging.bicep' = if(NodiniteLoggingEnabled == 'true' && ApplicationInsightsLoggingEnabled == 'true'){
  name: 'FunctionApp-BothLogging-${dateTime}'
  params: {
    location: location
    functionAppName: functionAppName
    serverFarmResourceId: appServicePlan.resourceId
    functionAppSettings: functionAppEnvironmentSettings
    applicationInsightResourceId: sharedAppInsights.id
    sharedResources: sharedResources
  }
}

// No logging enabled
module functionAppWithNoLoggingEnabled './FunctionApp_Modules/FunctionApp_NoLogging.bicep' = if(NodiniteLoggingEnabled == 'false' && ApplicationInsightsLoggingEnabled == 'false'){
  name: 'FunctionApp-NoLogging-${dateTime}'
  params: {
    location: location
    functionAppName: functionAppName
    serverFarmResourceId: appServicePlan.resourceId
    functionAppSettings: functionAppEnvironmentSettings
  }
}



// Variables to handle outputs safely
var deployedFunctionApp = NodiniteLoggingEnabled == 'true' && ApplicationInsightsLoggingEnabled == 'false' ? functionAppWithNodinite : (ApplicationInsightsLoggingEnabled == 'true' && NodiniteLoggingEnabled == 'false' ? functionAppWithApplicationInsights : (NodiniteLoggingEnabled == 'true' && ApplicationInsightsLoggingEnabled == 'true' ? functionAppWithBothLoggingEnabled : functionAppWithNoLoggingEnabled))

// Output the correct systemAssignedPrincipalId based on which module was deployed
output defaultHostname string = deployedFunctionApp.outputs.defaultHostname
output name string = deployedFunctionApp.outputs.functionAppName
output resourceId string = deployedFunctionApp.outputs.functionAppId
output systemAssignedPrincipalId string = deployedFunctionApp.outputs.systemAssignedPrincipalId
