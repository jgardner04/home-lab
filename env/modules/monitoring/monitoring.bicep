resource la 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${basename}-la'
  location: location
  tags: tags
  identity: {
    type:'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: logAnalyticsRetention
  }
}

output logAnalyticsWorkspaceId string = la.id

param basename string
param location string
param tags object
param logAnalyticsRetention int = 60
