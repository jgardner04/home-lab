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
    vpnSiteIpAddress: vpnSiteIpAddress
    vpnSiteAddressSpace: vpnSiteAddressSpace
    sharedKey: vpnSharedKey
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

module monitoring 'modules/monitoring/monitoring.bicep' = {
  scope: resourceGroup(hubrg.name)
  name: 'monitoring'
  params: {
    basename: basename
    location: location
    tags: tags
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
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

param location string
var basename = 'home-lab'
var owner = 'jogardn'
var tags = {
  owner: owner
  purpose: 'home-lab'
}
param vpnSiteIpAddress string
param vpnSiteAddressSpace array = ['192.168.1.0/24']
param vpnSharedKey string
