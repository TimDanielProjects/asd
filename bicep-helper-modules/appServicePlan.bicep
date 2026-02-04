param dateTime string = utcNow()
param location string = resourceGroup().location
param appServicePlan {
  name: string
  skuName: string
  skuCapacity: int
  maximumScaleBurst: int
  elasticScaleEnabled: bool
}

module asp '../bicep-registry-modules/avm/res/web/serverfarm/main.bicep' = {
  name: '${appServicePlan.name}-${dateTime}'
  params: {
    name: appServicePlan.name
    location: location
    skuCapacity:appServicePlan.skuCapacity
    maximumElasticWorkerCount: appServicePlan.maximumScaleBurst // This is "maximum burst"
    elasticScaleEnabled: appServicePlan.elasticScaleEnabled
    skuName: appServicePlan.skuName
  }
}

output id string = asp.outputs.resourceId
output name string = asp.outputs.name
