targetScope = 'subscription'

resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${basename}-hub-rg'
  location: location
  tags: tags
}

resource aksrg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${basename}-aks-rg'
  location: location
  tags: tags
}

module vwan 'modules/networking/vWanHub.bicep' = {
  scope: resourceGroup(hubrg.name)
  name: 'vwan'
  params: {
    baseName: basename
    location: location
    tags: tags
    virtualnNetworkId: hubVnet.outputs.id
  }
}

module hubVnet 'modules/networking/vnet.bicep' = {
  scope: resourceGroup(hubrg.name)
  name: 'vnet'
  params: {
    name: '${basename}-hub-vnet'
    location: location
    tags: tags
    addressPrefixes: ['10.0.0.0/16']
  }
}

// Add AKS Cluster
module aks 'modules/aks/aks.bicep' = {
  scope: resourceGroup(aksrg.name)
  name: 'aks'
  params: {
    basename: basename
    location: location
    tags: tags
  }
}

param location string
var basename = 'home-lab'
var owner = 'jogardn'
var tags = {
  owner: owner
  purpose: 'home-lab'
}

