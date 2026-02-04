param dataFactoryName string
param managedVirtualNetworkName string
param privateEndpointName string?

resource managedVirtualNetwork 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = {
  name: '${dataFactoryName}/${managedVirtualNetworkName}'
  properties: {
    
  }
}

resource privateEndpoint 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = if (privateEndpointName != null) {
  parent: managedVirtualNetwork
  name: privateEndpointName!
  properties: {
    
  }
}