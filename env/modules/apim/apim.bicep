module apimPvtEndpoint '../vnet/privateendpoint.bicep' = {
  name: 'apiPrivateEndpoint'
  params: {
    privateEndpointName: '${apimName}-pvt-endpoint'
    subnetid: {
      id: apimSubnet.id
    }
    location: location
    privateLinkServiceConnections: privateLinkServiceConnections
  }
}

resource apimPip 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: '${apimName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource apimSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: '${vnetName}/${subnetName}'
}

resource apim 'Microsoft.ApiManagement/service@2021-12-01-preview' = {
  name: apimName
  location: location
  tags: tags
  sku: {
    capacity: skuCapacity
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    notificationSenderEmail: notificationSenderEmail
    privateEndpointConnections: [
      {
        id: apimPvtEndpoint.outputs.privateEndpointId
        name: apimPvtEndpoint.outputs.privateEndpointName
        type: 'Microsoft.ApiManagement/service/privateEndpointConnections'
      }
    ]
    publicIpAddressId:apimPip.id
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkConfiguration: {
      subnetResourceId: apimSubnet.id
    }
  }
}

param apimName string = 'apim'
param location string
param tags object
param skuCapacity int = 1
param skuName string = 'Developer_1'
param notificationSenderEmail string
param privateLinkServiceConnections array = []
param publisherEmail string
param publisherName string
param vnetName string
param subnetName string
