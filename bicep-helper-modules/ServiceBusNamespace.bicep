param dateTime string = utcNow()
param location string = resourceGroup().location
param serviceBus {
  namespaceName: string
  resourceGroupName: string
  sku: 'Basic' | 'Standard' | 'Premium' 

}
module serviceBusNamespace '../bicep-registry-modules/avm/res/service-bus/namespace/main.bicep' = {
  name: 'ServiceBusNamespace-${dateTime}'
  params:{
    managedIdentities: {
      systemAssigned:true
    }
    location: location
    name: serviceBus.namespaceName
    skuObject: {
      name: serviceBus.sku
    }
    disableLocalAuth:false
    publicNetworkAccess: 'Enabled'
    
  }
}

