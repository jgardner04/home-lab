resource kv 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${basename}-kv'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    accessPolicies: accessPolicy
    createMode: createMode
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enablePurgeProtection: enablePurgeProtection
    enableSoftDelete: enableSoftDelete
    tenantId: tenantId
  }
}

parameter basename string
parameter location string
parameter tags object
parameter skuName string = 'standard'
parameter accessPolicy array
parameter createMode string = 'default'
parameter enabledForDeployment bool = true
paramater enabledForDiskEncryption bool = true
parameter enabledForTemplateDeployment bool = true
parameter enablePurgeProtection bool = false
parameter enableSoftDelete bool = false
parameter tenantId string = subscription().tenantId
