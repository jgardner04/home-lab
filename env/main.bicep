targetScope = 'subscription'

resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${basename}-hub-rg'
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
  }
}

module vnet 'modules/networking/vNet.bicep' = {
  scope: resourceGroup(hubrg.name)
  name: 'vnet'
  params: {
    name: '${basename}-hub-vnet'
    location: location
    tags: tags
    addressPrefixes: ['10.0.0.0/16']
  }
}

param location string
var basename = 'home-lab'
var owner = 'jogardn'
var tags = {
  owner: owner
  purpose: 'home-lab'
}

