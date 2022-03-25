param namePrefix string
param location string
param tags object
param gatewaySubnetId string
param aksSubnetId string

resource acr 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: '${namePrefix}acr'
  location: location
  tags: tags

  sku: {
    name: 'Premium'
  }

  properties: {
    adminUserEnabled: false
    networkRuleBypassOptions: 'AzureServices'
    networkRuleSet: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: gatewaySubnetId
        }
        {
          action: 'Allow'
          id: aksSubnetId
        }
      ]
    }
    publicNetworkAccess: 'Disabled'
  }
}
