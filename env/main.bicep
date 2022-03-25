param location string
param localAddressPrefixes string
param localGatewayIpAddress string
param vpnPreSharedKey string

var basename = 'jogardn'
var owner = 'jogardn'

module vnet './network.bicep' = {
  name: 'network'
  params: {
    location: location
    vnetName: '${basename}-vnet'
    tags: {
      owner: owner
      resourceType: 'network'
    }
    localAddressPrefixes: localAddressPrefixes
    localGatewayIpAddress: localGatewayIpAddress
    vpnPreSharedKey: vpnPreSharedKey
  } 
}

module logging 'monitoring.bicep' = {
  name: 'monitoring'
  params: {
    namePrefix: basename
    location: location
    tags: {
      owner: owner
      resourceType: 'logging'
    }
  }
}

module storage 'storage.bicep' = {
  name: 'storage'
  params: {
    namePrefix: basename
    location: location
    tags: {
      owner: owner
      resourceType: 'storage'
    }
  }
}

module acr 'acr.bicep' = {
  name: 'acr'
  params: {
    namePrefix: basename
    location: location
    tags: {
      owner: owner
      resourceType: 'acr'
    }
    gatewaySubnetId: vnet.outputs.gatewaySubnetId
    aksSubnetId: vnet.outputs.aksSubnetId

  }
}

module aks 'aks.bicep' = {
  name: 'aks'
  params: {
    namePrefix: basename
    location: location
    tags: {
      owner: owner
      resourceType: 'aks'
    }
    aksSubnetId: vnet.outputs.aksSubnetId
    logWorkspaceId: logging.outputs.logWorkspaceId
    privateDnsId: vnet.outputs.privateDnsId
  }
}
