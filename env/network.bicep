param vnetName string
param location string
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties:{
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
        ]
      }
    }
}
