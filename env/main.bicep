targetScope = 'subscription'

resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${basename}-hub-rg'
  location: location
  tags: tags
}

resource aksrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${basename}-aks-rg'
  location: location
  tags: tags
}

resource devrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${basename}-dev-rg'
  location: location
  tags: tags
}

module hubvnet './modules/hub-default.bicep' = {
  name: 'hub-vnet'
  scope: resourceGroup(hubrg.name)
  params: {
    location: location
    hubFwName: 'hub-fw'
    tags: tags
    localAddressPrefixes: localAddressPrefixes
    localGatewayIpAddress: localGatewayIpAddress
    vpnPreSharedKey: vpnPreSharedKey
  }
}

module aksvnet './modules/vnet/vnet.bicep' = {
  name: 'aks-vnet'
  scope: resourceGroup(aksrg.name)
  params: {
    vnetName: 'aks-vnet'
    location: location
    vnetPrefix: '192.168.144.0/22'
    tags: tags
    subnets: [
      {
        name: 'nodes-subnet'
        subnetPrefix: '192.168.144.0/23'
        routeTableid: aksroutetable.outputs.routeTableid
      }
      {
        name: 'ingress-subnet'
        subnetPrefix: '192.168.146.0/24'
        routeTableid: ''
      }
      {
        name: 'acr'
        subnetPrefix: '192.168.147.0/24'
        routeTableid: ''
      }
      {
        name: apimVnetSubnetName
        subnetPrefix: '192.168.147.0/24'
        routeTableid: ''
      }
    ]
  }
}

resource subnetAcrPrivate 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  scope: resourceGroup(aksrg.name)
  name: '${aksvnet.name}/acr'
}

module acrPrivateEndpoint 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(aksrg.name)
  name: 'acrPrivateEndpoint'
  params: {
    privateEndpointName: 'acrPrivateEndpoint'
    location: location
    privateLinkServiceConnections: [
      {
        name: 'acrPrivateEndpointConnection'
        properties: {
          privateLinkServiceId: hubvnet.outputs.acrId
          groupIds: [
            'registry'
          ]
        }
      }
    ]
    subnetid: {
      id: subnetAcrPrivate.id
    }
  }
}

module devvnet './modules/vnet/vnet.bicep' = {
  name: 'dev-vnet'
  scope: resourceGroup(devrg.name)
  params: {
    location: location
    tags: tags
    vnetName: 'dev-vnet'
    vnetPrefix: '192.168.120.0/24'
    subnets: [
      {
        name: 'agents-subnet'
        subnetPrefix: '192.168.120.0/25'
        routeTableid: devroutetable.outputs.routeTableid
      }
      {
        name: 'PE-subnet'
        subnetPrefix: '192.168.120.224/27'
        routeTableid: ''
      }
    ]
    
  }
}

// Peer hub with aks vnets
module hubtoakspeering './modules/vnet/vnet-peering.bicep' = {
  name: 'hub-to-aks'
  scope: resourceGroup(hubrg.name)
  dependsOn: [
    hubvnet
    aksvnet    
  ]
  params:{
    localVnetName: hubvnet.name
    remoteVnetName: aksvnet.name
    remoteVnetID: aksvnet.outputs.vnetID
  }
}
module akstohubpeering './modules/vnet/vnet-peering.bicep' = {
  name: 'aks-to-hub'
  scope: resourceGroup(aksrg.name)
  dependsOn: [
    hubvnet
    aksvnet    
  ]
  params:{
    localVnetName: aksvnet.name
    remoteVnetName: hubvnet.name
    remoteVnetID: hubvnet.outputs.hubVnetId
  }
}
// Peer hub with dev vnets
module hubtodevpeering './modules/vnet/vnet-peering.bicep' = {
  name: 'hub-to-dev'
  scope: resourceGroup(hubrg.name)
  dependsOn: [
    hubvnet
    devvnet    
  ]
  params:{
    localVnetName: hubvnet.name
    remoteVnetName: devvnet.name
    remoteVnetID: devvnet.outputs.vnetID
  }
}
module devtohubpeering './modules/vnet/vnet-peering.bicep' = {
  name: 'dev-to-hub'
  scope: resourceGroup(devrg.name)
  dependsOn: [
    hubvnet
    devvnet    
  ]
  params:{
    localVnetName: devvnet.name
    remoteVnetName: hubvnet.name
    remoteVnetID: hubvnet.outputs.hubVnetId
  }
}

// Create & assign the route tables
module aksroutetable './modules/vnet/routetable.bicep'={
  name: 'aks-rt'
  scope: resourceGroup(aksrg.name)
  params:{
    location: location
    udrName: 'aks-rt'
    udrRouteName: 'Default-route'
    nextHopIpAddress: hubvnet.outputs.hubFwPrivateIPAddress
  }
}
module devroutetable './modules/vnet/routetable.bicep'={
  name: 'dev-rt'
  scope: resourceGroup(devrg.name)
  params:{
    location: location
    udrName: 'dev-rt'
    udrRouteName: 'Default-route'
    nextHopIpAddress: hubvnet.outputs.hubFwPrivateIPAddress
  }
}

// Create the AKS Cluster
module akscluster './modules/aks/aks-cluster.bicep' = {
  name: clusterName
  scope: resourceGroup(aksrg.name)
  params: {
    location: location
    tags: tags
    clusterName: clusterName
    nodeResourceGroup: '${clusterName}-nodes-rg' 
  }
}

// Link the private DNS zone of AKS to hub & dev vnets
module privatednshublink './modules/vnet/private-dns-vnet-link.bicep' = {
  name: 'link-to-hub-vnet'
  dependsOn: [
    akscluster
  ]
  scope: resourceGroup('${clusterName}-nodes-rg')
  params: {
    privatednszonename: akscluster.outputs.apiServerAddress
    registrationEnabled: false
    vnetID: hubvnet.outputs.hubVnetId
    vnetName: hubvnet.name
  }
} 
module privatednsdevlink './modules/vnet/private-dns-vnet-link.bicep' = {
  name: 'link-to-dev-vnet'
  dependsOn: [
    akscluster
  ]
  scope: resourceGroup('${clusterName}-nodes-rg')
  params: {
    privatednszonename: akscluster.outputs.apiServerAddress
    registrationEnabled: false
    vnetID: devvnet.outputs.vnetID
    vnetName: devvnet.name
  }
}

// Create Dev VM
module devVM './modules/devbox/devbox.bicep' = {
  name: 'devVm'
  dependsOn: [
    devvnet
    devroutetable
  ]
  scope: resourceGroup(devrg.name)
  params: {
    location: location
    devRgName: devrg.name
    adminUsername: adminUsername
    adminPassword: adminPassword
    tags: tags
    hubRgName: hubrg.name
  }
}

// Deploy APIM to the AKS RG
module apim './modules/apim/apim.bicep' = {
  name: 'apim'
  dependsOn: [
    aksvnet
  ]
  scope: resourceGroup(aksrg.name)
  params: {
    location: location
    tags: tags
    notificationSenderEmail: notificationSenderEmail
    publisherEmail: publisherEmail
    publisherName: publisherName
    vnetName: aksvnet.name
    subnetName: apimVnetSubnetName
  }
}

param location string
param localAddressPrefixes string
param localGatewayIpAddress string
param vpnPreSharedKey string
param clusterName string = 'aks-cl01'
var basename = 'home-lab'
var owner = 'jogardn'
@secure()
param adminUsername string
@secure()
param adminPassword string
var tags = {
  owner: owner
  purpose: 'home-lab'
}
param notificationSenderEmail string
param publisherEmail string
param publisherName string
param apimVnetSubnetName string = 'apim'
