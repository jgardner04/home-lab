targetScope = 'subscription'

param location string
// param localAddressPrefixes string
// param localGatewayIpAddress string
// param vpnPreSharedKey string

var basename = 'home-lab'
var owner = 'jogardn'
var tags = {
  owner: owner
  purpose: 'home-lab'
}

resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${basename}-hub-rg'
  location: location
  tags: tags
}

resource aksrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${basename}-aks-rg'
  location: location
  tags: tags
}

resource devrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${basename}-dev-rg'
  location: location
  tags: tags
}

module hubvnet './modules/hub-default.bicep' = {
  name: 'hub-vnet'
  scope: resourceGroup(hubrg.name)
  params: {
    location: location
    hubVnetName: '${basename}-hub-vnet'
    hubFwName: 'hub-fw'
    tags: tags
  }
}
