param namePrefix string
param location string
param tags object

var name = '${namePrefix}base64(namePrefix)'

resource diagStorage 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    
  }
}
