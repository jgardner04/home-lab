param location string
param localAddressPrefixes string
param localGatewayIpAddress string
param vpnPreSharedKey string

var basename = 'jogardn'

module vnet './network.bicep' = {
  name: 'network'
  params: {
    location: location
    vnetName: '${basename}-vnet'
    tags: {
      owner: 'jogardn'
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
    namePrefix: 'jogardn'
    location: location
    tags: {
      owner: 'jogardn'
      resourceType: 'logging'
    }
  }
}

module storage 'storage.bicep' = {
  name: 'storage'
  params: {
    namePrefix: 'jogardn'
    location: location
    tags: {
      owner: 'jogardn'
      resourceType: 'storage'
    }
  }
}
