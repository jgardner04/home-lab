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

module aksvnet './modules/vnet.bicep' = {
  name: 'aks-vnet'
  scope: resourceGroup(aksrg.name)
  params: {
    vnetName: 'aks-vnet'
    location: location
    vnetPrefix: '192.168.4.0/22'
    subnets: [
      {
        name: 'nodes-subnet'
        subnetPrefix: '192.168.4.0/23'
        routeTableid: aksroutetable.outputs.routeTableid
      }
      {
        name: 'ingress-subnet'
        subnetPrefix: '192.168.6.0/24'
        routeTableid: ''
      }
    ]

  }
}

module devvnet './modules/vnet.bicep' = {
  name: 'dev-vnet'
  scope: resourceGroup(devrg.name)
  params: {
    location: location
    vnetName: 'dev-vnet'
    vnetPrefix: '192.168.2.0/24'
    subnets: [
      {
        name: 'agents-subnet'
        subnetPrefix: '192.168.2.0/25'
        routeTableid: devroutetable.outputs.routeTableid
      }
      {
        name: 'PE-subnet'
        subnetPrefix: '192.168.2.224/27'
        routeTableid: ''
      }
    ]
    
  }
}

// Peer hub with aks vnets
module hubtoakspeering './modules/vnet-peering.bicep' = {
  name: 'hub-to-aks'
  scope: resourceGroup(hubrg.name)
  dependsOn: [
    hubvnet
    aksvnet    
  ]
  params:{
    localVnetName: hubvnet.name
    remoteVnetName: aksvnet.name
    remoteVnetRg: aksrg.name
    remoteVnetID: aksvnet.outputs.vnetID
  }
}
module akstohubpeering './modules/vnet-peering.bicep' = {
  name: 'aks-to-hub'
  scope: resourceGroup(aksrg.name)
  dependsOn: [
    hubvnet
    aksvnet    
  ]
  params:{
    localVnetName: aksvnet.name
    remoteVnetName: hubvnet.name
    remoteVnetRg: hubrg.name
    remoteVnetID: hubvnet.outputs.hubVnetId
  }
}
// Peer hub with dev vnets
module hubtodevpeering './modules/vnet-peering.bicep' = {
  name: 'hub-to-dev'
  scope: resourceGroup(hubrg.name)
  dependsOn: [
    hubvnet
    devvnet    
  ]
  params:{
    localVnetName: hubvnet.name
    remoteVnetName: devvnet.name
    remoteVnetRg: devrg.name
    remoteVnetID: devvnet.outputs.vnetID
  }
}
module devtohubpeering './modules/vnet-peering.bicep' = {
  name: 'dev-to-hub'
  scope: resourceGroup(devrg.name)
  dependsOn: [
    hubvnet
    devvnet    
  ]
  params:{
    localVnetName: devvnet.name
    remoteVnetName: hubvnet.name
    remoteVnetRg: hubrg.name
    remoteVnetID: hubvnet.outputs.hubVnetId
  }
}

// Create & assign the route tables
module aksroutetable './modules/routetable.bicep'={
  name: 'aks-rt'
  scope: resourceGroup(aksrg.name)
  params:{
    location: location
    udrName: 'aks-rt'
    udrRouteName: 'Default-route'
    nextHopIpAddress: hubvnet.outputs.hubFwPrivateIPAddress
  }
}
module devroutetable './modules/routetable.bicep'={
  name: 'dev-rt'
  scope: resourceGroup(devrg.name)
  params:{
    location: location
    udrName: 'dev-rt'
    udrRouteName: 'Default-route'
    nextHopIpAddress: hubvnet.outputs.hubFwPrivateIPAddress
  }
}
