param namePrefix string
param location string
param tags object

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${namePrefix}-analytics'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'Standard'
    }
  }
}
