// Create a virtualWan
resource virtualWan 'Microsoft.Network/virtualWans@2022-07-01' = {
  name: '${baseName}-vwan'
  location: location
  tags: tags
  properties: {
    type: 'Standard'
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
  }
}

// Create a virtualWAN hub
resource vwanHub 'Microsoft.Network/virtualHubs@2022-05-01' = {
  name: '${baseName}-vwan-hub'
  location: location
  tags: tags
  properties: {
    addressPrefix: '10.1.0.0/16'
    virtualWan: {
      id: virtualWan.id
    }
  }
}

resource hubNetworkConnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2022-07-01' = {
  parent: vwanHub
  name: '${baseName}-vwan-hub-vnet-connection'
  dependsOn: [
    firewall
  ]
  properties: {
    remoteVirtualNetwork: {
      id: virtualnNetworkId
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: false
    enableInternetSecurity: true
    routingConfiguration: {
      associatedRouteTable: {
        id: hubRouteTable.id
      }
      propagatedRouteTables: {
        labels: [
          'VNet'
        ]
        ids: [
          {
            id: hubRouteTable.id
          }
        ]
      }
    }
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2022-07-01' = {
  name: '${baseName}-firewall'
  location: location
  properties: {
    sku:{
      name: 'AZFW_Hub'
      tier: 'Standard'
    }
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    virtualHub: {
      id: vwanHub.id
    }
  }
}

resource routeTable 'Microsoft.Network/routeTables@2022-07-01' = {
  name: 'RT-01'
  location: location
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'jump-to-inet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}

resource hubRouteTable 'Microsoft.Network/virtualHubs/routeTables@2022-05-01' = {
  parent: vwanHub
  name: '${baseName}-vwan-hub-route-table'
  properties: {
    labels: [
      'VNet'
    ]
    routes: [
      {
        name: 'WorkloadToFirewall'
        destinationType: 'CIDR'
        destinations: [
          '10.0.1.0/24'
        ]
        nextHopType: 'ResourceId'
        nextHop: firewall.id
      }
      {
        name: 'InternetToFirewall'
        destinationType: 'Internet'
        destinations: [
          '0.0.0.0/0'
        ]
        nextHopType: 'ResourceId'
        nextHop: firewall.id
      }
    ]
  }
}


param baseName string
param location string
param tags object
param virtualnNetworkId string
