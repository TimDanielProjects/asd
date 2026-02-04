param dateTime string = utcNow()
param location string = resourceGroup().location
param keyVaultName string
param APIManagementService {
  Name: string
  PublisherName: string
  PublisherEmail: string
  APIMTier: 'Basic' | 'BasicV2' | 'Consumption' | 'Developer' | 'Premium' | 'Standard' | 'StandardV2' | null
}

@description('List of products to create subscriptions for.')
param products array = [
  'internal'
  //'product2'
]

module apim '../bicep-registry-modules/avm/res/api-management/service/main.bicep' = {
  name: 'apim-${dateTime}'
  params: {
    location: location
    name: APIManagementService.Name
    publisherEmail: APIManagementService.PublisherEmail
    publisherName: APIManagementService.PublisherName
    managedIdentities:{
      systemAssigned:true
    }
    sku: APIManagementService.?APIMTier
    namedValues:[
      {
        name: 'tenant-id'
        displayName: 'tenant-id'
        value: subscription().tenantId
      }
    ]
  }
}

module apimSettings 'APIM_Settings.bicep' = [for product in products:{
  name: 'apimSettings-${product}-${dateTime}'

  params:{
    apimName: APIManagementService.Name
    apimResourceId: apim.outputs.resourceId
    product: product
    keyVaultName: keyVaultName
  }
}]

output principalId string = apim.outputs.?systemAssignedMIPrincipalId!
output name string = apim.outputs.name
