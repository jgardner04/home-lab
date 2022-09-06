resource appGateway 'Microsoft.Network/applicationGateways@2022-01-01' = {
  name: 'appGateway'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 10
    }
    backendAddressPools: backendAddressPools
  }
}

param location string
param tags object
param backendAddressPools array
