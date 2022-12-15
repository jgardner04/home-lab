resource virtualNetwork 'Microsoft.Network/virtualnetworks@2015-05-01-preview' = {
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
