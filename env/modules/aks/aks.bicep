module aksVnet '../networking/vnet.bicep' = {
  name: 'aksVnet'
  params: {
    name: '${basename}-aks-vnet'
    location: location
    tags: tags
    addressPrefixes: [
      '10.0.10.0/16'
    ]
  }
}


param basename string
param location string
param tags object
