param kvName string
param policyName string
param accessPolicy object

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
}

resource kvAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: policyName
  parent: keyVault
  properties: {
    accessPolicies: [
      accessPolicy
    ]
  }
}
