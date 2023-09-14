targetScope = 'subscription'

// Import the home-lab group 
resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' existing = {
  name: 'home-lab'
}


// Import the monitoring RG
resource rgMonitoring 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: 'monitoring'
}

resource la 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: 'home-network'
  scope: resourceGroup(rgMonitoring.name)
}

// Create AKS Cluster from module
module aks 'modules/aks/aks.bicep' = {
  scope: resourceGroup(rg.name)
  name: '${basename}-aks'
  params: {
    basename: basename
    location: location
    tags: tags
    logAnalyticsWorkspaceId: la.id
    azureMonitorWorkspaceResourceId: rgMonitoring.id
  }
}

param location string
var basename = 'home-lab'
var owner = 'jogardn'
var tags = {
  owner: owner
  purpose: 'home-lab'
}
