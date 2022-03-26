param vnetName string
param location string
param tags object
param localAddressPrefixes string
param localGatewayIpAddress string
param vpnPreSharedKey string


var privateDnsName = 'privatelink.${location}.azmk8s.io'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties:{
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
        ]
      }
    subnets: [
      {
        id: 'gatewaySubnet'
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.1.0.0/22'
          serviceEndpoints: [
            {
              locations: [
                location
              ]
              service: 'Microsoft.ContainerRegistry'
            }
          ]
        }
      }
      {
        id: 'aks'
        name: 'AksSubnet'
        properties: {
          addressPrefix: '10.2.0.0/16'
          serviceEndpoints: [
            {
              locations: [
                location
              ]
              service: 'Microsoft.ContainerRegistry'
            }
          ]
        }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'gatewayPip'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
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
            id: vnet.properties.subnets[0].id
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw2'
      tier: 'VpnGw2'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
  }
}

resource vpnConnection 'Microsoft.Network/connections@2021-05-01' = {
  name: '${vnetName}-home-connection'
  location: location
  properties: {
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    routingWeight: 0
    sharedKey: vpnPreSharedKey
    enableBgp: false
    localNetworkGateway2: {
      id: localGateway.id
      properties: {

      }
    }
    virtualNetworkGateway1: {
      id: vpnGateway.id
      properties: {}
    }
    connectionMode: 'Default'
    dpdTimeoutSeconds: 0
  }
}

resource privateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsName
  location: 'global'
  tags: tags
  properties: {}
}

resource privateDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${vnetName}PrivateDnsLink'
  location: 'global'
  tags: tags
  parent: privateDns
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnet.id
    }
  }
}

output vnetId string = vnet.id
output gatewaySubnetId string = vnet.properties.subnets[0].id
output aksSubnetId string = vnet.properties.subnets[1].id
output privateDnsId string = privateDns.id
