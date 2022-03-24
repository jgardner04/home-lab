param vnetName string
param location string
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties:{
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
        ]
      }
    }
}

resource gatewaySubnet 'Microsoft.Network/virtualnetworks/subnets@2015-06-15' = {
  name: 'GatewaySubnet'
  parent: vnet
  properties: {
    addressPrefix: '10.1.1.0/24'
  }
}

resource localGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  name: '${vnetName}-local-gateway'
  location: location
  tags: tags
  properties: {
    activeActive: false
    gatewayType: 'LocalGateway'
    sku: {
      name: 'Standard'
      tier: 'Standard'
    }
  }
}

