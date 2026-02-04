param NodiniteLoggingSettings {
  nodiniteBlobContainerName: string
  nodiniteStorageAccountName: string
  nodiniteFunctionBlobContainerName: string
  EventHubSettings: {
    eventHubNamespaceName: string
    partitioncount: int
    mmessageRetentionInDays: int
    nodiniteLoggingEventHubName: string
    captureDescriptionEnabled: bool
    captureDescriptionDestinationBlobContainer: string
  }
}
param dateTime string = utcNow()
param location string = resourceGroup().location
param APIMSettings {
  name: string
  tier: 'Basic' | 'BasicV2' | 'Consumption' | 'Developer' | 'Premium' | 'Standard' | 'StandardV2' | null
  publisherEmail: string
  publisherName: string
}
param environmentSuffix string

module eventhubsNamespace '../../bicep-helper-modules/EventHubNamespace.bicep' = {
  name: 'eventHubNamespace-Main-${dateTime}'
  params: {
    eventHubNamespaceName: NodiniteLoggingSettings.EventHubSettings.eventHubNamespaceName
    
  }
}

// Storage account for Nodinite logging
module nodiniteStorageAccount '../../bicep-helper-modules/NodiniteStorageAccount.bicep' = {
  name: 'StorageAccount-NodiniteLogging-Main-${dateTime}'
  params: {
    storageAccountParams: {
      name: NodiniteLoggingSettings.nodiniteStorageAccountName
    }
    nodiniteLogging_blobName: NodiniteLoggingSettings.nodiniteBlobContainerName
    nodiniteLogging_FunctionBlobName: NodiniteLoggingSettings.nodiniteFunctionBlobContainerName
    nodiniteLogging_EventHub_CheckpointCaptureContainerName: NodiniteLoggingSettings.EventHubSettings.captureDescriptionDestinationBlobContainer
  }
}

// Create managed identity for Nodinite
module Nodinite_managedIdentity '../../bicep-registry-modules/avm/res/managed-identity/user-assigned-identity/main.bicep' = {
  name: 'managedIdentity'
  params: {
    name: 'NodiniteManagedIdentity${environmentSuffix}'
  }
}

module Nodinite_RBAC '../AccessControlWithRBAC/Nodinite_RBAC.bicep' = {
  params: {
    RBACSettings: {
      NodiniteStorageAccountSettings: {
        storageAccountName: nodiniteStorageAccount.outputs.name
        roleAssignments: [
          {
            roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
            principalId: Nodinite_managedIdentity.outputs.principalId
            principalType: 'ServicePrincipal'
          }
        ]
      }
    }
  }
}

module NodiniteLogging_eh_la '../../bicep-registry-modules/avm/res/event-hub/namespace/eventhub/main.bicep' = {
  name: 'NodiniteLogging_eh_la-${dateTime}'
  params: {
    name: NodiniteLoggingSettings.EventHubSettings.nodiniteLoggingEventHubName
    namespaceName: NodiniteLoggingSettings.EventHubSettings.eventHubNamespaceName
    messageRetentionInDays: NodiniteLoggingSettings.EventHubSettings.mmessageRetentionInDays
    retentionDescriptionRetentionTimeInHours: 24* NodiniteLoggingSettings.EventHubSettings.mmessageRetentionInDays
    partitionCount: NodiniteLoggingSettings.EventHubSettings.partitioncount
    status: 'Active'
  }
}

module apim '../../bicep-registry-modules/avm/res/api-management/service/main.bicep' = {
  name: 'apim-update_for_nodinite_logging${dateTime}'
  params: {
    location: location
    name: APIMSettings.name
    publisherEmail: APIMSettings.publisherEmail
    publisherName: APIMSettings.publisherName
    managedIdentities: {
      systemAssigned: true
      userAssignedResourceIds: [
        Nodinite_managedIdentity.outputs.resourceId
      ]
    }
    sku: APIMSettings.?tier
    namedValues: [
      {
        name: 'logging-blob-mid-client-id'
        displayName: 'logging-blob-mid-client-id'
        value: Nodinite_managedIdentity.outputs.clientId
      }
      {
        name: 'logging-blob-url'
        displayName: 'logging-blob-url'
        value: 'https://${NodiniteLoggingSettings.nodiniteStorageAccountName}.blob.${environment().suffixes.storage}/${NodiniteLoggingSettings.nodiniteBlobContainerName}/'
      }
    ]
  }
}

//Create the All API policy for logging to Nodinite
module allApiPolicy '../../bicep-registry-modules/avm/res/api-management/service/policy/main.bicep' = {
  name: 'allApiPolicy'
  dependsOn: [
    apim
    genericNodiniteLoggingPolicyFragmentLoadContent
  ]
  params: {
    format: 'rawxml'
    apiManagementServiceName: APIMSettings.name
    value: loadTextContent('../../generic-policy-files/allApiPolicy.xml')
  }
}
//Generic policy fragment for logging to Nodinite
resource genericNodiniteLoggingPolicyFragmentLoadContent 'Microsoft.ApiManagement/service/policyFragments@2024-06-01-preview' ={
  dependsOn: [
    apim
  ]
  name: '${APIMSettings.name}/genericNodiniteLoggingPolicyFragment'
  properties: {
    format: 'rawxml'
    description: 'Generic policy fragment for logging to Nodinite'
    value: loadTextContent('../../generic-policy-files/genericNodiniteLoggingPolicyFragment.xml')
  }
}
