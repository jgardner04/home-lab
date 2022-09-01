param location string
param devRgName string
param hubRgName string
@secure()
param adminUsername string
@secure()
param adminPassword string
param tags object
param kvName string = 'jogardn-kv'
var extensionName = 'GuestAttestation'

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
    securityRules: [
      {
        name: 'allow-3389-home-ip'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '192.168.1.0/24'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
  tags: tags
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'VM-01'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: any('Standard_E4bs_v5')
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
      dataDisks: [
        {
          name: 'DS-02'
          createOption: 'Empty'
          diskSizeGB: 1024
          lun: 0
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          deleteOption: 'Delete'
        }
      ]
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
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    osProfile: {
      computerName: 'VM-01'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    licenseType: 'Windows_Client'
  }
  tags: tags
  resource attestation 'extensions' = {
    name: extensionName
    location: location
    properties: {
      type: 'GuestAttestation'
      typeHandlerVersion: '1.0'
      publisher: 'Microsoft.Azure.Security.WindowsAttestation'
      autoUpgradeMinorVersion: true
      settings: {
        AttestationEndpointCfg: {
          maaEndpoint: 'https://sharedwus.wus.attest.azure.net/'
          maaTenantName: 'GuestAttestation'
          ascReportingEndpoint: 'https://sharedwus.wus.attest.azure.net/'
          useAlternativeToken: false
          disableAlerts: false
        }
      }
    }
  }
}

resource hubRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  scope: subscription()
  name: hubRgName
}

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
  scope: resourceGroup(hubRg.name)
}

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: 'kvPvtEndpoint'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: devSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'kvPvtEndpoint'
        properties: {
          groupIds: [
            'vault'
          ]
          privateLinkServiceId: kv.id
        }
      }
    ]
  }
}
