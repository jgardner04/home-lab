param location string
param devRgName string
param kvName string = 'jogardn-kv'
@secure()
param adminUsername string
@secure()
param adminPassword string
param tags object

resource devResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  scope: subscription()
  name: devRgName
}

resource devSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  scope: resourceGroup(devResourceGroup.name)
  name: 'dev-vnet/agents-subnet'
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: 'NI-01'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: devSubnet.id
          }
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
  tags: tags
}

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'SG-01'
  location: location
  properties: {
    securityRules: []
  }
  tags: tags
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: 'VM-01'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: any('Standard_D8s_v5')
    }
    storageProfile: {
      imageReference: {
        publisher: 'microsoftwindowsdesktop'
        offer: 'windows-11'
        sku: 'win11-21h2-ent'
        version: 'latest'
      }
      osDisk: {
        name: 'DS-01'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    osProfile: {
      computerName: 'VM-01'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          enableHotpatching: false
        }
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    licenseType: 'Windows_Client'
  }
  tags: tags
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
  scope: resourceGroup(devResourceGroup.name)
}

resource accessPolicy 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'Microsoft.Bicep'
  resourceGroup: 'Platform'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      'contentVersion': '1.0.0.0'
      'resources': [
        {
          'type': 'Microsoft.KeyVault/vaults/accessPolicies'
          'apiVersion': '2021-06-01-preview'
          'name': '${keyVault.name}/add'
          'properties': {
            'accessPolicies': [
              {
                'objectId': '${virtualMachine.identity.principalId}'
                'tenantId': '${tenant().tenantId}'
                'permissions': {
                  'keys': [
                    'list'
                    'get'
                    'decrypt'
                    'encrypt'
                    'unwrapKey'
                    'wrapKey'
                  ]
                  'secrets': [
                    'list'
                    'get'
                  ]
                }
              }
            ]
          }
        }
      ]
    }
  }
}



resource diskEncryption 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  parent: virtualMachine
  name: 'diskEncryption'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryption'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
    settings: {
      'EncryptionOperation': 'EnableEncryption'
      'KeyVaultURL': 'https://${keyVault.name}${environment().suffixes.keyvaultDns}'
      'KeyVaultResourceId': keyVault.id
      'VolumeType': 'All'
    }
  }
}
