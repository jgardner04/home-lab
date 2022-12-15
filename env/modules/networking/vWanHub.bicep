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
      propagatedRouteTables: [
        ids: [
          {
          id: hubRouteTable.id
        }
      ]
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

resource hubRouteTable 'Microsoft.Network/virtualHubs/routeTables@2022-07-01' = {
  parent: vwanHub
  name: '${baseName}-vwan-hub-route-table'
  properties: {
    routes: [
      
    ]
  }
}


param baseName string
param location string
param tags object
param virtualnNetworkId string
