param namePrefix string
param location string
param tags object
param aksSubnetId string
param logWorkspaceId string

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
        name: '${namePrefix}-agent'
        count: 2
        enableAutoScaling: true
        enableEncryptionAtHost: true
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
        vmSize: 'Standard_D4s_v4'
        vnetSubnetID: aksSubnetId
      }
    ]
    apiServerAccessProfile: {
      authorizedIPRanges: [
        '10.1.0.0/22'
      ]
      enablePrivateCluster: true
      enablePrivateClusterPublicFQDN: false
      privateDNSZone: 'aks.gardner.local'
    }
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }
    dnsPrefix: '${namePrefix}aks'
    enableNamespaceResources: true
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
