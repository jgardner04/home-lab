
resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-11-01' = {
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
        osType: 'Linux'
        enableAutoScaling: true
        minCount: 1
        maxCount: 5
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
      networkPlugin: 'kubenet'
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
param aksClusterDnsPrefix string = '${basename}-aks'
param nodePoolName string = 'linux'
param nodePoolCount int = 1
param nodePoolVmSize string = 'Standard_D8s_v3'
param logAnalyticsWorkspaceId string
