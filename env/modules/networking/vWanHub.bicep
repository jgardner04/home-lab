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

param baseName string
param location string
param tags object
