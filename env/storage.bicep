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

resource fileservices 'Microsoft.Storage/storageAccounts/fileServices@2021-09-01' = {
  name: 'default'
  parent: filestorage
  properties: {
    protocolSettings: {
      smb: {
        authenticationMethods: 'NTLMv2'
        channelEncryption: 'AES-256-GCM'
        multichannel: {
          enabled: true
        }
        versions: 'SMB3.0,SMB3.1.1'
      }
    }
  }
}

resource fileshare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-09-01' = {
  name: 'workstation-backup'
  parent: fileservices
  properties: {
    accessTier: 'Premium'
    enabledProtocols: 'SMB'
    metadata: {}
    shareQuota: 5120
  }
}
