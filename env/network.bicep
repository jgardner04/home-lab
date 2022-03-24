param vnetName string
param location string
param tags object
param localAddressPrefixes string
param localGatewayIpAddress string

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

resource pip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'gatewayPip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource localGateway 'Microsoft.Network/localNetworkGateways@2021-05-01' = {
  name: '${vnetName}-local-gateway'
  location: location
  tags: tags
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        '${localAddressPrefixes}'
      ]
    }
    gatewayIpAddress: localGatewayIpAddress
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  name: '${vnetName}-vpn-gateway'
  location: location
  tags: tags
  properties: {
    activeActive: false
    ipConfigurations: [
      {
        id: 'vpnGateway'
        name: 'vpnGateway'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: gatewaySubnet.id
          }
        }
      }
    ]
    sku: {
      name: 'Standard'
      tier: 'Standard'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
  }
}
