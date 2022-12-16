resource aksVnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: '${basename}-aks-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: aksVnetAddressPrefix
    }
  }
}

resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: 'aksSubnet'
  parent: aksVnet
  properties: {
    addressPrefix: aksSubnetPrefix
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-09-01' = {
  name: '${basename}-aks'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  properties: {
    dnsPrefix: aksClusterDnsPrefix
    agentPoolProfiles: [
      {
        name: toLower(nodePoolName)
        count: nodePoolCount
        vmSize: nodePoolVmSize
        vnetSubnetID: aksSubnet.id
        osType: 'Linux'
        enableAutoScaling: true
        mode: 'System'
        type: 'VirtualMachineScaleSets'
      }
    ]
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceId
        }
      }
    }
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      loadBalancerSku: 'standard'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
    }
  }
}

param basename string
param location string
param tags object
param aksVnetAddressPrefix array = ['10.1.0.0/16']
param aksSubnetPrefix string = '10.1.1.0/24'
param aksClusterDnsPrefix string = '${basename}-aks'
param nodePoolName string = 'linux'
param nodePoolCount int = 1
param nodePoolVmSize string = 'Standard_D8s_v3'
param logAnalyticsWorkspaceId string
