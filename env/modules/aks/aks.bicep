module aksVnet '../networking/vnet.bicep' = {
  name: 'aksVnet'
  params: {
    name: '${basename}-aks-vnet'
    location: location
    tags: tags
    addressPrefixes: [
      '10.1.0.0/16'
    ]
  }
}



param basename string
param location string
param tags object
