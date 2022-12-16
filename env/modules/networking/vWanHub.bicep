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
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-07-01' = {
  name: 'Policy-01'
  location: location
  properties: {
    threatIntelMode: 'Alert'
  }
}

resource firewallRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-07-01' = {
  parent: firewallPolicy
  name: 'DefaultApplicationRuleCollectionGroup'
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'RC-01'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'Allow-msft'
            sourceAddresses: [
              '*'
            ]
            protocols: [
              {
                port: 80
                protocolType: 'Http'
              }
              {
                port: 443
                protocolType: 'Https'
              }
            ]
            targetFqdns: [
              '*.microsoft.com'
            ]
          }
        ]
      }
    ]
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

resource hubRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2022-05-01' = {
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
        destinationType: 'CIDR'
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
