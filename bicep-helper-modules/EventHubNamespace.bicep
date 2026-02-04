param eventHubNamespaceName string
param location string = resourceGroup().location
param dateTime string = utcNow()
module eventHubNamespace '../bicep-registry-modules/avm/res/event-hub/namespace/main.bicep' = {
  name: 'EventhubNamespace-${dateTime}'
  params: {
    location: location
    name: eventHubNamespaceName
    managedIdentities:{
      systemAssigned:true
    }
    disableLocalAuth: false
  }
}

output eventHubResourceId string = eventHubNamespace.outputs.resourceId
output systemAssignedMIPrincipalId string = eventHubNamespace.outputs.?systemAssignedMIPrincipalId!
output name string = eventHubNamespace.outputs.name
