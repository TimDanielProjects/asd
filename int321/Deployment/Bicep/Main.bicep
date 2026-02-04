@minLength(3)
param integrationId string
param regionSuffix string
param organisationSuffix string
param environmentSuffix string
param NodiniteLoggingEnabled string
param ApplicationInsightsLoggingEnabled string
param location string = resourceGroup().location
param dateTime string = utcNow()

// Variables
var resourceBaseName = toLower('${organisationSuffix}-int-${integrationId}')
var sharedResourceBaseName = toLower('${organisationSuffix}-int-shared')
var resourceEnding = toLower('${regionSuffix}-${environmentSuffix}')
var sharedResourceGroup = {name: '${sharedResourceBaseName}-rg-${resourceEnding}'}
var keyVaultName = '${sharedResourceBaseName}-kv-${resourceEnding}'
var fixedKeyVaultName = '${sharedResourceBaseName}-kv-${toLower(environmentSuffix)}'
var storageAccountName = 'st${uniqueString(organisationSuffix,integrationId,environmentSuffix)}'
var logicAppName= '${resourceBaseName}-la-${resourceEnding}'
var functionAppName = '${resourceBaseName}-fa-${resourceEnding}'

// Existing resources
resource sharedAPIM 'Microsoft.ApiManagement/service@2022-08-01' existing = {
  name: '${sharedResourceBaseName}-apim-${resourceEnding}'
  scope: resourceGroup(sharedResourceGroup.name)
}
resource sharedServiceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: '${sharedResourceBaseName}-sbns-${resourceEnding}'
  scope: resourceGroup(sharedResourceGroup.name)
}
resource sharedLogicAppASP 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: '${sharedResourceBaseName}-aspla-${resourceEnding}'
  scope: resourceGroup(sharedResourceGroup.name)
}
resource sharedKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: length(keyVaultName) <= 24 ? keyVaultName : fixedKeyVaultName
  scope: resourceGroup(sharedResourceGroup.name)
}
resource sharedEventhubNamespace 'Microsoft.EventHub/namespaces@2024-05-01-preview' existing = {
  name: '${sharedResourceBaseName}-ehns-${resourceEnding}'
  scope: resourceGroup(sharedResourceGroup.name)
}
resource sharedFunctionApp 'Microsoft.Web/sites@2022-09-01' existing = {
  name: '${sharedResourceBaseName}-fa-${resourceEnding}'
  scope: resourceGroup(sharedResourceGroup.name)
}
resource sharedStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: 'st${uniqueString(organisationSuffix,'shared',environmentSuffix)}'
  scope: resourceGroup(sharedResourceGroup.name)
}
resource sharedAppInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${sharedResourceBaseName}-ai-${resourceEnding}'
  scope: resourceGroup(sharedResourceGroup.name)
}


//Storage Account
module storageAccount '../../../bicep-helper-modules/StorageAccount.bicep' = {
  name: 'StorageAccount-Main-${dateTime}'
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}


// Logic App Standard
module logicAppStandard '../../../bicep-helper-modules/LogicAppStandard.bicep' = {
  name: 'LogicAppStandard-Main-${dateTime}'
  params: {
    location: location
    logicAppName: logicAppName
    environmentSuffix: environmentSuffix
    organisationSuffix: organisationSuffix
    ApplicationInsightsLoggingEnabled: ApplicationInsightsLoggingEnabled
    NodiniteLoggingEnabled: NodiniteLoggingEnabled
    sharedResources: {
      sharedAPIMName: sharedAPIM.name
      sharedAppServicePlanName: sharedLogicAppASP.name
      sharedAppServicePlanResourceId: sharedLogicAppASP.id
      sharedEventHubsNamespaceName: sharedEventhubNamespace.name
      sharedEventHubsNamespaceResourceId: sharedEventhubNamespace.id
      sharedFunctionAppName: sharedFunctionApp.name
      sharedKeyVaultName: sharedKeyVault.name
      sharedResourceGroupName: sharedResourceGroup.name
      sharedServiceBusNamespaceName: sharedServiceBusNamespace.name
      sharedServiceBusNamespaceResourceId: sharedServiceBusNamespace.id
      sharedApplicationInsightsName: sharedAppInsights.name
    }
    storageAccount: {
      resourceId: storageAccount.outputs.resourceId
      name: storageAccount.outputs.name
    }
  }
}

//RBAC
module RBAC '../../../bicep-helper-modules/AccessControlWithRBAC/RBAC.bicep' = {
  name: 'RBAC-Main-${dateTime}'
  params: {
    //Resources to access with RBAC
    RBACSettings: {
      storageAccountSettings: {
        storageAccountName: storageAccount.outputs.name
        roleAssignments: [
          {
            principalId: logicAppStandard.outputs.systemAssignedPrincipalId
            roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
            // 'Storage Blob Data Contributor'
          }
          {
            principalId: logicAppStandard.outputs.systemAssignedPrincipalId
            roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/69566ab7-960f-475b-8e7c-b3118f30c6bd'
            // Storage File Share Contributor
          }
        ]
      }
    }
  }
}
//RBAC for shared resources
module RBAC_Shared_Resources '../../../bicep-helper-modules/AccessControlWithRBAC/RBAC.bicep' = {
  name: 'RBAC_Shared_Resources-Main-${dateTime}'
  scope: resourceGroup(sharedResourceGroup.name)
  params: {
    //Resources to access with RBAC
    RBACSettings: {
      apimSettings: {
        name: sharedAPIM.name
        roleAssignments: [
          {
            principalId: logicAppStandard.outputs.systemAssignedPrincipalId
            roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/312a565d-c81f-4fd8-895a-4e21e48d571c'
            //'API Management Service Contributor'
          }
        ]
      }
      serviceBusNamespaceSettings: {
        namespaceName: sharedServiceBusNamespace.name
        roleAssignments: [
          {
            principalId: logicAppStandard.outputs.systemAssignedPrincipalId
            roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/090c5cfd-751d-490a-894a-3ce6f1109419'
            //'Azure Service Bus Data Owner'
          }
        ]
      }
      keyVaultSettings: {
        keyVaultName: sharedKeyVault.name
        roleAssignments: [
          {
            principalId: logicAppStandard.outputs.systemAssignedPrincipalId
            roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6'
            //'Key Vault Secrets User'
          }
        ]
      }
      storageAccountSettings: {
        storageAccountName: sharedStorageAccount.name
        roleAssignments: [
          {
            principalId: logicAppStandard.outputs.systemAssignedPrincipalId
            roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
            // 'Storage Blob Data Contributor'
          }
          {
            principalId: logicAppStandard.outputs.systemAssignedPrincipalId
            roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/69566ab7-960f-475b-8e7c-b3118f30c6bd'
            //Storage File Share Contributor
          }
        ]
      }
    }
  }
}

// Outputs
output functionAppName string = functionAppName
output logicAppStandardName string = logicAppName
