param dateTime string = utcNow()
param location string = resourceGroup().location
param logAnalyticsname string
module Log '../bicep-registry-modules/avm/res/operational-insights/workspace/main.bicep' = {
  name: 'logAnalytics-${dateTime}'
  params: {
    location: location
    name: logAnalyticsname
  }
}

output logAnalyticsResourceId string = Log.outputs.resourceId
