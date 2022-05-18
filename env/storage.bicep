param namePrefix string
param location string
param tags object


resource diagStorage 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: '${namePrefix}diagstorage'
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
    }
  }
}


resource filestorage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: '${namePrefix}filestorage'
  location: location
  tags: tags
  sku: {
    name: 'Premium_LRS'
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}
