param namePrefix string
param location string
param tags object
param aksSubnetId string
param logWorkspaceId string
param privateDnsId string

resource aks 'Microsoft.ContainerService/managedClusters@2022-01-02-preview' = {
  name: '${namePrefix}-aks'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 2
        enableAutoScaling: true
        enableNodePublicIP: false
        mode: 'System'
        maxCount: 5
        minCount: 2
        maxPods: 50
        osType: 'Linux'
        osDiskType: 'Ephemeral'
        osDiskSizeGB: 40
        osSKU: 'Ubuntu'
        scaleDownMode: 'Delete'
        scaleSetEvictionPolicy: 'Delete'
        tags: tags
        type: 'VirtualMachineScaleSets'
        vmSize: 'Standard_DS3_v2'
        vnetSubnetID: aksSubnetId
      }
    ]
    apiServerAccessProfile: {
      enablePrivateCluster: true
      enablePrivateClusterPublicFQDN: false
      privateDNSZone: privateDnsId
    }
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }
    dnsPrefix: '${namePrefix}aks'
    enablePodSecurityPolicy: false
    enableRBAC: true
    networkProfile: {
      dockerBridgeCidr: '172.17.0.1/16'
      ipFamilies: [
        'IPv4'
      ]
      loadBalancerSku: 'standard'
      networkPlugin: 'kubenet'
      networkPolicy: 'calico'
      outboundType: 'loadBalancer'
    }
    nodeResourceGroup: '${namePrefix}-aksInfraRG'
    addonProfiles: {
      omsagent: {
        config: {
          logAnalyticsWorkspaceResourceID: logWorkspaceId
        }
        enabled: true
      }
    }
  }
}
