param namePrefix string
param location string
param tags object
param vnetId string

var name = '${namePrefix}diagstorage'

resource diagStorage 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: vnetId
          state: 'Succeeded'
        }
      ]
    }
  }
}
