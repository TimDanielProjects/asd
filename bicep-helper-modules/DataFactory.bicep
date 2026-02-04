param DataFactoryName string
param dateTime string = utcNow()

module dataFactory '../bicep-registry-modules/avm/res/data-factory/factory/main.bicep' = {
  name: 'DataFactory-${dateTime}'
  params: {
    name: DataFactoryName
    managedIdentities: {
      systemAssigned: true
    }
  }
}

output id string = dataFactory.outputs.resourceId
output name string = dataFactory.outputs.name
