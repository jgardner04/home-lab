resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
  }
}

output id string = virtualNetwork.id

param name string
param location string
param tags object
param addressPrefixes array
