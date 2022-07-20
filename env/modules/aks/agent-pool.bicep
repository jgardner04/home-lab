param poolName string
param parentName string
param properties object

resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' existing = {
  name: parentName
}

resource agentPool 'Microsoft.ContainerService/managedClusters/agentPools@2022-05-02-preview' = {
  name: poolName
  parent: aksCluster
  properties: properties
}
