param location string
param localAddressPrefixes string
param localGatewayIpAddress string

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
  } 
}
